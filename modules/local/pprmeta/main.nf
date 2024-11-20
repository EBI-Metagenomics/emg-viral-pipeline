process PPRMETA {
    label 'process_medium'
    tag "${meta.id}"
    container 'quay.io/microbiome-informatics/pprmeta:1.1'

    input:
      tuple val(meta), path(fasta), val(contig_number)
      path(pprmeta_git)
    
    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(meta), path("${meta.id}_pprmeta.csv")

    script:
      """
      export MCR_CACHE_ROOT="${task.workDir}/mcr_cache_root"
      [ -d "pprmeta" ] && cp pprmeta/* .
      ./PPR_Meta ${fasta} ${meta.id}_pprmeta.csv
      """
}

 // .fasta is not working here. has to be .fa
 // need to implement this so its fixed 

process pprmetaGet {
  container 'nanozoo/template:3.8--ccd0653'
  label 'process_single'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/pprmeta", mode: 'copy', pattern: "*" 
  }
  else { 
    storeDir "${params.databases}/pprmeta" 
  }  

  output:
    path("*")

  script:
    """
    git clone https://github.com/mult1fractal/PPR-Meta.git
    mv PPR-Meta/* .  
    rm -r PPR-Meta
    """
}
