process pprmeta {
      label 'pprmeta'
      publishDir "${params.output}/${name}/${params.virusdir}/pprmeta", mode: 'copy', pattern: "${name}_pprmeta.csv"

    input:
      tuple val(name), file(fasta), val(contig_number)
      path(pprmeta_git)
    
    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("${name}_pprmeta.csv")

    script:
      """
      [ -d "pprmeta" ] && cp pprmeta/* .
      ./PPR_Meta ${fasta} ${name}_pprmeta.csv
      """
}

 // .fasta is not working here. has to be .fa
 // need to implement this so its fixed 

process pprmetaGet {
  label 'noDocker'    
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
