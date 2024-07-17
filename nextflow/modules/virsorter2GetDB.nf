process virsorter2GetDB {
  label 'virsorter2'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/virsorter2/", mode: 'copy', pattern: "virsorter2-data" 
  }
  else { 
    storeDir "${params.databases}/virsorter2/" 
  }  

  output:
    path("virsorter2-data", type: 'dir')
    
  script:
    """
    # just in case there is a failed attemp before; 
    #   remove the whole diretory specified by -d
    rm -rf virsorter2-data
    # run setup
    #virsorter setup -d virsorter2-data -j ${task.cpus}
    wget https://osf.io/v46sc/download
    mkdir virsorter2-data
    tar -xzf db.tgz -C virsorter2-data
    """
}
