process viphogGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/", mode: 'copy', pattern: "vpHMM_database_${params.version}" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/" 
  }  

  output:
    file("vpHMM_database_${params.version}")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpHMM_database_${params.version}.tar.gz && tar -zxvf vpHMM_database_${params.version}.tar.gz
    rm vpHMM_database_${params.version}.tar.gz
    """
}


 // roughly 3 GB size