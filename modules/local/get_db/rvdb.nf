process rvdbGetDB {
  label 'process_low'    
  container 'nanozoo/template:3.8--ccd0653'    
  
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
