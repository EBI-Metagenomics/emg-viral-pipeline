process HMM_POSTPROCESSING {
    /*
    input: File_hmmer_ViPhOG.tbl
    output: File_hmmer_ViPhOG_modified.tbl
    */
    
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
      tuple val(name), val(set_name), file(hmmer_tbl), file(faa) 
    
    output:
      tuple val(name), val(set_name), file("${set_name}_modified.tsv"), file(faa)
    
    script:
    """
    hmmscan_format_table.py -t ${hmmer_tbl} -o ${set_name}_modified
    """
}


