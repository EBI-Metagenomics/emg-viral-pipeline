process vpfGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/", mode: 'copy', pattern: "vpf" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/" 
  }  

  output:
    file("vpf")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpf.tar.gz && tar -zxvf vpf.tar.gz
    rm vpf.tar.gz
    """
}
