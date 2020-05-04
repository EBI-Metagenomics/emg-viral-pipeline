process ratio_evalue {
      errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
      publishDir "${params.output}/${name}/ratio_evalue_tables", mode: 'copy', pattern: "${set_name}_modified_informative.tsv"
      label 'ratio_evalue'

    input:
      tuple val(name), val(set_name), file(modified_table), file(faa)
      file(model_metadata)
    
    output:
      tuple val(name), val(set_name), file("${set_name}_modified_informative.tsv"), file(faa)
    
    shell:
    """
    [ -d "models" ] && cp models/* .
    ratio_evalue_table.py -i ${modified_table} -t ${model_metadata} -o .
    """
}
/* Description:          Generates tabular file (File_informative_ViPhOG.tsv) listing results per protein, which include the ratio of the aligned target profile and the abs value of the total Evalue

	parser = argparse.ArgumentParser(description = "Generate dataframe that stores the profile alignment ratio and total e-value for each ViPhOG-query pair")
	parser.add_argument("-i", "--input", dest = "input_file", help = "domtbl generated with Generate_vphmm_hmmer_matrix.py", required = True)
	parser.add_argument("-o", "--outdir", dest = "outdir", help = "Directory where you want output table to be stored (default: cwd)", default = ".")

out PRJNA530103_small_modified_informative.tsv
*/


process metaGetDB {
  label 'ratio_evalue'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/models", mode: 'copy', pattern: "Additional_data_vpHMMs.dict" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/models" 
  }  
    
    output:
      file("Additional_data_vpHMMs.dict")
    
    shell:
    """
    # v2 of metadata file
#    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/Additional_data_vpHMMs_v2.xlsx
#    generate_vphmm_object.py -x Additional_data_vpHMMs_v2.xlsx -o Additional_data_vpHMMs.dict

    # v1 of metadata file
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/Additional_data_vpHMMs.xlsx
    generate_vphmm_object.py -x Additional_data_vpHMMs.xlsx -o Additional_data_vpHMMs.dict
    """
}

