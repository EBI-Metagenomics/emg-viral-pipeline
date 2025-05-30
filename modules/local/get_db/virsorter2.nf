process virsorter2GetDB {
  label 'virsorter2'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/virsorter2/", mode: 'copy', pattern: "virsorter2-data" 
  }
  else { 
    storeDir "${params.databases}/virsorter2/" 
  }  

  output:
    path("virsorter2-data/db", type: 'dir')

  script:
    """
    # just in case there is a failed attemp before; 
    # remove the whole diretory specified by -d
    rm -rf virsorter2-data
    
    # download virsorter2 database and extract
    wget https://osf.io/v46sc/download
    mkdir virsorter2-data
    tar -xzf download -C virsorter2-data
    """
}