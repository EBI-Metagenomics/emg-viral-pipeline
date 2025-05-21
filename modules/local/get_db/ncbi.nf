process ncbiGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/ncbi/", mode: 'copy', pattern: "ete3_ncbi_tax.sqlite" 
  }
  else { 
    storeDir "${params.databases}/ncbi/" 
  }  

  output:
    path("ete3_ncbi_tax.sqlite")

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/2022-11-01_ete3_ncbi_tax.sqlite.gz && gunzip -f 2022-11-01_ete3_ncbi_tax.sqlite.gz
    cp 2022-11-01_ete3_ncbi_tax.sqlite ete3_ncbi_tax.sqlite
    """
}
