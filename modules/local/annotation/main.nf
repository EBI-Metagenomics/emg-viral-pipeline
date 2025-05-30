process ANNOTATION {
/*
	'''This function takes a fasta file containing the proteins predicted in a set of putative viral contigs and a dataframe that collates the
	   results obtained with hmmer against the ViPhOG database for the same proteins'''

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
    tag "${meta.id} ${set_name}"
    label 'process_single'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.1'
    
    input:
      tuple val(meta), val(set_name), path(tab), path(faa) 
    
    output:
      tuple val(meta), val(set_name), path("*_annotation.tsv"), emit: annotations
    
    script:
    """
    viral_contigs_annotation.py -o . -p ${faa} -t ${tab}
    """
}