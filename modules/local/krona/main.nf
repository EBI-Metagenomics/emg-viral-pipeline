process KRONA {
    label 'process_low'  
    tag "${meta.id} ${set_name}"
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krona:2.8.1--pl5321hdfd78af_1':
        'biocontainers/krona:2.8.1--pl5321hdfd78af_1' }"
    
    input:
      tuple val(meta), val(set_name), file(input_file)
    output:
      file("*.krona.html")
      
    script:
      """
      export accession="${meta.id}"
      if [ "${set_name}" != "all" ]; then
        export accession="${set_name}"
      fi
      
      ktImportText -n ${meta.id} -o \${accession}.krona.html ${input_file}
      """
}
