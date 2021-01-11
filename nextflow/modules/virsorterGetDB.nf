process virsorterGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/virsorter/", mode: 'copy', pattern: "virsorter-data" 
  }
  else { 
    storeDir "${params.databases}/virsorter/" 
  }  

  output:
    path("virsorter-data", type: 'dir')
    
  script:
    """
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virsorter-data-v2.tar.gz 
    tar -xvzf virsorter-data-v2.tar.gz
    rm virsorter-data-v2.tar.gz
    """
}


 // roughly 4 GB size