process virsorterGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/virsorter/", mode: 'copy', pattern: "virsorter-data" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/virsorter/" 
  }  

  output:
    file("virsorter-data")
  script:
    """
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virsorter-data-v2.tar.gz 
    tar -xvzf virsorter-data-v2.tar.gz
    rm virsorter-data-v2.tar.gz
    """
}


 // roughly 4 GB size