process vpfGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "vpf" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("vpf", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpf.tar.gz && tar -zxvf vpf.tar.gz
    rm vpf.tar.gz
    """
}
