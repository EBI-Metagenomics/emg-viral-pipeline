process PRODIGAL {
    label 'process_medium'
    tag "${meta.id} ${confidence_set_name}"
    container 'quay.io/biocontainers/prodigal:2.6.3--hec16e2b_4'
    
    input:
      tuple val(meta), val(confidence_set_name), path(fasta) 
    
    output:
      tuple val(meta), val(confidence_set_name), path("${confidence_set_name}_prodigal.faa"), emit: proteins
      tuple val(meta), val(confidence_set_name), path("${confidence_set_name}_prodigal.gff"), emit: gff

    script:
    """
    prodigal -p "meta" -a ${confidence_set_name}_prodigal.faa -f gff -o ${confidence_set_name}_prodigal.gff -i ${fasta}
    """
}

// error 18 in prodigal is when no input sequences can be detected
