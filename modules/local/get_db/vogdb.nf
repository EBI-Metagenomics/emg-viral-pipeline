process vogdbGetDB {
  label 'process_low'    
  container 'nanozoo/template:3.8--ccd0653'  
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "vogdb" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("vogdb", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vogdb.tar.gz && tar -zxvf vogdb.tar.gz
    rm vogdb.tar.gz
    """
}
