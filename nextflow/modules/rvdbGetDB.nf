process rvdbGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/", mode: 'copy', pattern: "rvdb" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/" 
  }  

  output:
    file("rvdb")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/rvdb.tar.gz && tar -zxvf rvdb.tar.gz
    rm rvdb.tar.gz
    """
}
