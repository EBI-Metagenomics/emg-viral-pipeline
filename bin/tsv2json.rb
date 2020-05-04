#!/usr/bin/env ruby

# hoelzer.martin@gmail.com

#12	root	Viruses	Caudovirales	Siphoviridae	Fromanvirus	unclassified Fromanvirus	Mycobacterium phage Naca
#10	root	Viruses	Caudovirales	Siphoviridae	Dismasvirus	unclassified Dismasvirus	Microbacterium phage Didgeridoo
#8	root	Viruses	unclassified    Baculoviridae	Betabaculovirus	unclassified Betabaculovirus    Spodoptera litura granulovirus

TSV = File.open(ARGV[0], 'r')
JSON = File.open(ARGV[1], 'w')

# instead if this cutoff I filter the TSV for the top x categories before to avoid messy sankey
#cutoff = ARGV[1].to_i

id2taxa = {}
sum_for_taxa = {}
taxa_count = 0
TSV.each do |line|
    split = line.chomp.split("\t")
    count = split[0].to_i
   
    #next if count < cutoff
    
    # nodes
    lineage = split[2,split.size]

    lineage.each do |taxa|
        unless id2taxa[taxa]
            id2taxa[taxa] = taxa_count
            taxa_count += 1
        end
    end

    lineage_depth = lineage.size - 1
    lineage_depth.times do |i|
        j = i + 1
        break if j > lineage_depth
        t1 = lineage[i] #viruses
        t2 = lineage[j] #caudovirales
        t1_id = id2taxa[t1] #0
        t2_id = id2taxa[t2] #1
        pair = "#{t1_id}:#{t2_id}" #0:1
        if sum_for_taxa[pair]
            sum_for_taxa[pair] += count
        else
            sum_for_taxa[pair] = count
        end
    end
end
TSV.close

JSON << '{"nodes":[' << "\n"
pos = 1
id2taxa.each do |name, id|
    if pos == id2taxa.keys.size
        JSON << "\t{\"name\":\"#{name}\",\"id\":#{id}}\n\t],\"links\":[\n"
    else
        JSON << "\t{\"name\":\"#{name}\",\"id\":#{id}},\n"
    end
    pos += 1
end
pos = 1
sum_for_taxa.each do |pair, count|
    t1 = pair.split(":")[0]
    t2 = pair.split(":")[1]
    if pos == sum_for_taxa.keys.size
        JSON << "\t{\"source\":#{t1},\"target\":#{t2},\"value\":#{count}}\n\t]}\n"
    else
        JSON << "\t{\"source\":#{t1},\"target\":#{t2},\"value\":#{count}},\n"
    end
    pos += 1
end
JSON.close