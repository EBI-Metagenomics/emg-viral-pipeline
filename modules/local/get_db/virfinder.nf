process virfinderGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  publishDir "${params.databases}/virfinder", pattern: "VF.modEPV_k8.rda", mode: params.cloudProcess ? 'copy' : 'symlink'

  output:
    path "VF.modEPV_k8.rda"
  
  script:
    """
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virfinder/VF.modEPV_k8.rda
    """
}