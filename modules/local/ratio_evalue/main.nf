process RATIO_EVALUE {
    /* Description:          
    Generates tabular file (File_informative_ViPhOG.tsv) listing results per protein, which include the ratio of the aligned target profile and the abs value of the total Evalue
      parser = argparse.ArgumentParser(description = "Generate dataframe that stores the profile alignment ratio and total e-value for each ViPhOG-query pair")
      parser.add_argument("-i", "--input", dest = "input_file", help = "domtbl generated with Generate_vphmm_hmmer_matrix.py", required = True)
      parser.add_argument("-o", "--outdir", dest = "outdir", help = "Directory where you want output table to be stored (default: cwd)", default = ".")
    
    out PRJNA530103_small_modified_informative.tsv
    */
    tag "${meta.id} ${set_name}"
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.1'
    
    input:
      tuple val(meta), val(set_name), path(modified_table)
      path(model_metadata)
    
    output:
      tuple val(meta), val(set_name), path("${set_name}_modified_informative.tsv"), optional: true
    
    script:
    """
    [ -d "models" ] && cp models/* .
    ratio_evalue_table.py -i ${modified_table} -t ${model_metadata} -o ${set_name}_modified_informative.tsv -e ${params.evalue}
    """
}

