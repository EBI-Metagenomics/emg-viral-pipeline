process ncbiGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.cloudDatabase}/ncbi/", mode: 'copy', pattern: "ete3_ncbi_tax.sqlite" 
  }
  else { 
    storeDir "nextflow-autodownload-databases/ncbi/" 
  }  

  output:
    file("ete3_ncbi_tax.sqlite")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/ete3_ncbi_tax.sqlite.gz && gunzip -f ete3_ncbi_tax.sqlite.gz
    """
}
