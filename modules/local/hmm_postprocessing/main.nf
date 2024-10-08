process HMM_POSTPROCESSING {
    /*
    input: File_hmmer_ViPhOG.tbl
    output: File_hmmer_ViPhOG_modified.tbl
    */
    tag "${meta.id} ${set_name}"    
    label 'process_single'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
      tuple val(meta), val(set_name), path(hmmer_tbl), path(faa) 
    
    output:
      tuple val(meta), val(set_name), path("${set_name}_modified.tsv"), path(faa)
    
    script:
    """
    hmmscan_format_table.py -t ${hmmer_tbl} -o ${set_name}_modified
    """
}


