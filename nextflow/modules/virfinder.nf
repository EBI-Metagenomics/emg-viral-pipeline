process virfinder {
      errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
      publishDir "${params.output}/${name}/${params.virusdir}/virfinder", mode: 'copy', pattern: "${name}.txt"
      label 'virfinder'
    
    input:
      tuple val(name), file(fasta), val(contig_number)
      path model
    
    when: 
      contig_number.toInteger() > 0 
    
    output:
      tuple val(name), file("${name}.txt")
    
    script:
      """
      run_virfinder.Rscript ${model} ${fasta} .
      awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$4}' ${name}*.tsv > ${name}.txt
      """
}

process virfinderGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/virfinder/", mode: 'copy', pattern: "VF.modEPV_k8.rda" 
  }
  else { 
    storeDir "${params.databases}/virfinder/" 
  }  

  output:
    path "VF.modEPV_k8.rda"
  
  script:
    """
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virfinder/VF.modEPV_k8.rda
    """
}
