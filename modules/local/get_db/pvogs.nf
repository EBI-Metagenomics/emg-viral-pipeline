process pvogsGetDB {

  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'    
  
  publishDir "${params.databases}", pattern: "pvogs", mode: params.cloudProcess ? 'copy' : 'symlink'

  output:
    path("pvogs", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/pvogs.tar.gz && tar -zxvf pvogs.tar.gz
    rm pvogs.tar.gz
    """
}
