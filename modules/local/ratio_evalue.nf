process ratio_evalue {
      errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
      publishDir "${params.output}/${name}/ratio_evalue_tables", mode: 'copy', pattern: "${set_name}_modified_informative.tsv"
      label 'ratio_evalue'

    input:
      tuple val(name), val(set_name), file(modified_table), file(faa)
      file(model_metadata)
    
    output:
      tuple val(name), val(set_name), file("${set_name}_modified_informative.tsv"), file(faa), optional: true
    
    script:
    """
    [ -d "models" ] && cp models/* .
    ratio_evalue_table.py -i ${modified_table} -t ${model_metadata} -o ${set_name}_modified_informative.tsv -e ${params.evalue}
    """
}
/* Description:          Generates tabular file (File_informative_ViPhOG.tsv) listing results per protein, which include the ratio of the aligned target profile and the abs value of the total Evalue

	parser = argparse.ArgumentParser(description = "Generate dataframe that stores the profile alignment ratio and total e-value for each ViPhOG-query pair")
	parser.add_argument("-i", "--input", dest = "input_file", help = "domtbl generated with Generate_vphmm_hmmer_matrix.py", required = True)
	parser.add_argument("-o", "--outdir", dest = "outdir", help = "Directory where you want output table to be stored (default: cwd)", default = ".")

out PRJNA530103_small_modified_informative.tsv
*/
