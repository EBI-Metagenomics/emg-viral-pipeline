process virfinderGetDB {
  label 'process_low'    
  container 'nanozoo/template:3.8--ccd0653'
  
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