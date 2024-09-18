process annotation {
      //publishDir "${params.output}/${name}/${params.finaldir}", mode: 'copy', pattern: "*_annotation.tsv"
      publishDir "${params.output}/${name}/${params.finaldir}/annotation/", mode: 'copy', pattern: "*_annotation.tsv"
      label 'annotation'

    input:
      tuple val(name), val(set_name), file(tab), file(faa) 
    
    output:
      tuple val(name), val(set_name), file("*_annotation.tsv")
    
    script:
    """
    viral_contigs_annotation.py -o . -p ${faa} -t ${tab}
    """
}

/*
	'''This function takes a fasta file containing the proteins predicted in a set of putative viral contigs and a dataframe that collates the
	   results obtained with hmmscan against the ViPhOG database for the same proteins'''

      input_fasta: prodigal/output_fasta
      input_table: ratio_evalue/informative_table
      input_fna: fasta_file

	parser = argparse.ArgumentParser(description = "Generate tabular file with ViPhOG annotation results for proteins predicted in viral contigs")
	parser.add_argument("-p", "--prot", dest = "prot_file", help = "Relative or absolute path to protein file of predicted viral contigs", required = True)
	parser.add_argument("-t", "--table", dest = "ratio_file", help = "Relative or absolute path to ratio_evalue tabular file generated for predicted viral contigs", required = True)
	parser.add_argument("-o", "--outdir", dest = "output_dir", help = "Relative path to directory where you want the output file to be stored (default: cwd)", default = ".")
	parser.add_argument("-n", "--name", dest="name_file",
						help="Name of processing .fna file to write correct output name")

*/