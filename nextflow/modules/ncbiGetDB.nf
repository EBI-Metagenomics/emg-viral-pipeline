process ncbiGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/ncbi/", mode: 'copy', pattern: "ete3_ncbi_tax.sqlite" 
  }
  else { 
    storeDir "${params.databases}/ncbi/" 
  }  

  output:
    file("ete3_ncbi_tax.sqlite")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/ete3_ncbi_tax.sqlite.gz && gunzip -f ete3_ncbi_tax.sqlite.gz
    """
}
