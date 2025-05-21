process virfinderGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
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