process PRODIGAL {
    label 'process_medium'
    tag "${meta.id}"
    container 'quay.io/biocontainers/prodigal:2.6.3--hec16e2b_4'
    
    input:
      tuple val(meta), path(fasta) 
    
    output:
      tuple val(meta), path("${meta.id}_prodigal.gff"), path("${meta.id}_prodigal.faa"), emit: proteins_files

    script:
    """
    prodigal -p "meta" -a ${meta.id}_prodigal.faa -f gff -o ${meta.id}_prodigal.gff -i ${fasta}
    """
}

// error 18 in prodigal is when no input sequences can be detected
