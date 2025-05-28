process rvdbGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'    
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "rvdb" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("rvdb", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/rvdb.tar.gz && tar -zxvf rvdb.tar.gz
    rm rvdb.tar.gz
    """
}
