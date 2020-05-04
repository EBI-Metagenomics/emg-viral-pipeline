#!/usr/bin/env ruby

require 'bio'

assembly = ARGV[0]
annotations = File.open(ARGV[1],'r')
contigs = File.open(ARGV[2],'w')
filter = ARGV[4].to_i
n = 30

Bio::FastaFormat.open(assembly).each do |entry|
    id = entry.definition.chomp
    seq = entry.seq.chomp
    length = seq.length
    contigs << "#{id}\t1\t#{length}\n"
end
contigs.close

contigs_h = {}
contigs = File.open(ARGV[2],'r')
contigs.each do |line|
    s = line.split("\t")
    id = s[0]
    length = s[2].to_f
    if length > filter 
        contigs_h[id] = length    
    end
end
contigs.close
puts contigs_h
sorted = contigs_h.sort_by { |id, length| length }
contigs_h = sorted.to_h
puts "selected #{contigs_h.size} contigs larger #{filter} nt"
puts contigs_h

# now check the ratio between shortest and longest contig
# based on the code before they are sorted
shortest_contig  = contigs_h.values[0]
puts shortest_contig
longest_contig = contigs_h.values[contigs_h.values.length-1]
puts longest_contig
ratio = shortest_contig / longest_contig
while (ratio < 0.015) 
    longest_contig_id = contigs_h.keys[contigs_h.values.length-1]
    contigs_h.delete(longest_contig_id)
    shortest_contig  = contigs_h.values[0]
    longest_contig = contigs_h.values[contigs_h.values.length-1]
    ratio = shortest_contig / longest_contig    
end
contigs.close

# write new contig map out, split if many entries
i = 0
chunk = true
chunk_n = 0
contigs_out = false
contig_ids_chunked = {}
contigs_h.each do |id, length|
    if i == n
        chunk = true
        chunk_n += 1
        i = 0
        contigs_out.close
    end
    if chunk
        contig_ids_chunked[chunk_n] = []
        contigs_out = File.open(ARGV[2].sub('.contigs',".filtered-#{chunk_n}.contigs"),'w')
        chunk = false
    end
    contig_ids_chunked[chunk_n].push(id)
    contigs_out << "#{id}\t1\t#{length.to_i}\n"
    i += 1
end

# read in annotations
no = []
hc = []
lc = []
annotations.each do |line|  
    s = line.split("\t")

    contig = s[0]
    cds = s[1]
    start = s[2]
    stop = s[3]
    strand = s[4]
    hit = s[5].chomp
    score = s[6].to_i
    taxa = s[7]

    if hit == 'No hit'
        no.push("#{cds}\t#{contig}\t#{start}\t#{stop}\tNo hit\n") 
    else
        if score < 10 
            lc.push("#{cds}\t#{contig}\t#{start}\t#{stop}\tLow confidence\n")
        else
            hc.push("#{cds}\t#{contig}\t#{start}\t#{stop}\tHigh confidence\n")
        end
    end
end
annotations.close

anno_tmp_out = File.open('anno.txt','w')
hc.each do |entry|
    anno_tmp_out << entry
end
lc.each do |entry|
    anno_tmp_out << entry
end
no.each do |entry|
    anno_tmp_out << entry
end
anno_tmp_out.close

# now filter the annotations and only select those that match remaining contigs
# select now for each chunked file the correct annotations
contig_ids = contigs_h.keys
contig_ids_chunked.each do |chunk_id, chunk_contig_id_a|
    anno_out = File.open(ARGV[3].sub('.anno',".filtered-#{chunk_id}.anno"),'w')
    anno = File.open(anno_tmp_out,'r')
    anno.each do |line|
        id = line.split("\t")[1]
        if chunk_contig_id_a.include?(id)
            anno_out << line
        end
    end
    anno_out.close
    anno.close
end
