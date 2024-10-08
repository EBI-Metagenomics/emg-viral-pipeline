process PRODIGAL {
    label 'process_medium'
    tag "${meta.id} ${confidence_set_name}"
    container 'quay.io/biocontainers/prodigal:2.6.3--hec16e2b_4'
    
    input:
      tuple val(meta), val(confidence_set_name), path(fasta) 
    
    output:
      tuple val(meta), val(confidence_set_name), path("*.faa")
    
    script:
    """
    prodigal -p "meta" -a ${confidence_set_name}_prodigal.faa -i ${fasta}
    """
}

// error 18 in prodigal is when no input sequences can be detected
