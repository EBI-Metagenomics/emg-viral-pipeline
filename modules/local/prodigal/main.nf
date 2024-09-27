process PRODIGAL {
    label 'process_high'
    
    container 'quay.io/biocontainers/prodigal:2.6.3--hec16e2b_4'
    
    input:
      tuple val(assembly_name), val(confidence_set_name), file(fasta) 
    
    output:
      tuple val(assembly_name), val(confidence_set_name), file("*.faa")
    
    script:
    """
    prodigal -p "meta" -a ${confidence_set_name}_prodigal.faa -i ${fasta}
    """
}

// error 18 in prodigal is when no input sequences can be detected
