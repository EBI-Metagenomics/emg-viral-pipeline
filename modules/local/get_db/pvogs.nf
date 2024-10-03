process pvogsGetDB {

  label 'process_low'    
  container 'nanozoo/template:3.8--ccd0653'    
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "pvogs" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("pvogs", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/pvogs.tar.gz && tar -zxvf pvogs.tar.gz
    rm pvogs.tar.gz
    """
}
