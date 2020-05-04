#!/usr/bin/env ruby

# hoelzer.martin@gmail.com

# Combine the filtered blast results with meta information from the IMG/VR database.

filtered_blast_hits = File.open(ARGV[0], 'r')
meta_information_out = File.open(ARGV[0].sub('.blast','.meta'), 'w')
meta_information_tsv = File.open(ARGV[1], 'r')

# read in meta information
l = 0
meta_header = ''
meta_h = {}
meta_information_tsv.each do |line|
    if l == 0
        meta_header << line.chomp
    else
        s = line.chomp.split("\t")
        id = s[0]
        meta_h[id] = line.chomp
    end
    l += 1
end
puts "read in #{meta_h.size} meta information entries."

l = 0
blast_header = ''
filtered_blast_hits.each do |hit|
    if l == 0
        blast_header << hit.chomp
        meta_information_out << "#{blast_header}\t#{meta_header}\n"
        l += 1
    else
        hit_target_id = hit.split("\t")[1].sub('REF:','')
        meta_info = meta_h[hit_target_id]
        meta_information_out << "#{hit.chomp}\t#{meta_info}\n"
    end
end

filtered_blast_hits.close
meta_information_out.close
meta_information_tsv.close