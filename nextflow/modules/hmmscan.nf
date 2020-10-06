process hmmscan {
      publishDir "${params.output}/${name}/${params.hmmerdir}/${params.db}", mode: 'copy', pattern: "${set_name}_${params.db}_hmmscan.tbl"
      label 'hmmscan'

    input:
      tuple val(name), val(set_name), file(faa) 
      file(db)
    
    output:
      tuple val(name), val(set_name), file("${set_name}_${params.db}_hmmscan.tbl"), file(faa)
    
    script:
    """
    hmmscan --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${params.db}_hmmscan.tbl ${db}/${db}.hmm ${faa}
    """
}
