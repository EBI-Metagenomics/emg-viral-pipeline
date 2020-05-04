process pvogsGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/", mode: 'copy', pattern: "pvogs" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/" 
  }  

  output:
    file("pvogs")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/pvogs.tar.gz && tar -zxvf pvogs.tar.gz
    rm pvogs.tar.gz
    """
}
