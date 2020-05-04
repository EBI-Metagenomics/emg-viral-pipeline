#!/usr/bin/env ruby

input = File.open(ARGV[0],'r')
output = File.open(ARGV[1],'w')

input.each do |line|
    s = line.split("\t")
    output_string = "#{s[0]}\troot\tViruses\t#{s[1]}"
    j = -1
    element_before = ''
    s.each do |element|
        j += 1
        if j >= 2
            if element == "unclassified"
                output_string << "\tunclassified #{element_before}"
            else
                output_string << "\t#{element}"
            end
        end
        element_before = element
    end
    output << "#{output_string}"
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
#50	root	Viruses	unclassified
#4	root	Viruses	Caudovirales	Podoviridae	Autographivirinae	T7likevirus
#2	root	Viruses	Caudovirales	Podoviridae	unclassified Podoviridae	P22likevirus
#2	root	Viruses	unclassified	Microviridae	unclassified Microviridae	Microvirus	
#1	root	Viruses	Caudovirales	Siphoviridae
#1	root	Viruses	Caudovirales	Myoviridae	Peduovirinae