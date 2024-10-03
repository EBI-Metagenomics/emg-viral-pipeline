process vpfGetDB {
  label 'process_low'    
  container 'nanozoo/template:3.8--ccd0653'
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "vpf" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("vpf", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpf.tar.gz && tar -zxvf vpf.tar.gz
    rm vpf.tar.gz
    """
}
