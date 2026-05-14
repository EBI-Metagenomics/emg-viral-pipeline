process vpfGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  publishDir "${params.databases}", pattern: "vpf", mode: params.cloudProcess ? 'copy' : 'symlink'

  output:
    path("vpf", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpf.tar.gz && tar -zxvf vpf.tar.gz
    rm vpf.tar.gz
    """
}
