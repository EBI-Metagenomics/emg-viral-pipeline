#!/usr/bin/env ruby

input = File.open(ARGV[0], 'r')
output = File.open(ARGV[1], 'w')

input.each do |line|
    s = line.chomp.split("\t")
    count = s[0]
    lineage = s[1..]

    output_string = "#{count}\troot"

    if lineage[0] == "undefined" || lineage[0] == "unclassified"
        output_string << "\tViruses"
    end

    previous = ""
    lineage.each do |taxon|
        if taxon == "undefined" || taxon == "unclassified"
            output_string << "\tundefined #{previous}"
        else
            output_string << "\t#{taxon}"
        end
        previous = taxon
    end

    output.puts output_string
end

input.close
output.close


#INPUT
#50	unclassified
#4	Caudovirales	Podoviridae	Autographivirinae	T7likevirus
#2	Caudovirales	Podoviridae	unclassified	P22likevirus
#2	unclassified	Microviridae	unclassified	Microvirus	
#1	Caudovirales	Siphoviridae
#1	Caudovirales	Myoviridae	Peduovirinae

#OUTPUT
#50	root	Viruses	undefined
#4	root	Viruses	Caudovirales	Podoviridae	Autographivirinae	Tlikevirus
#2	root	Viruses	Caudovirales	Podoviridae	undefined Podoviridae	P22likevirus
#2	root	Viruses	undefined	Microviridae	undefined Microviridae	Microvirus	
#1	root	Viruses	Caudovirales	Siphoviridae
#1	root	Viruses	Caudovirales	Myoviridae	Peduovirinae