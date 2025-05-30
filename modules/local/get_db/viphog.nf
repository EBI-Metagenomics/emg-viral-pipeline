process viphogGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'   
  
  if (params.cloudProcess) { 
    publishDir "${params.databases}/", mode: 'copy', pattern: "vpHMM_database_${params.viphog_version}" 
  }
  else { 
    storeDir "${params.databases}/" 
  }  

  output:
    path("vpHMM_database_${params.viphog_version}", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpHMM_database_${params.viphog_version}.tar.gz && tar -zxvf vpHMM_database_${params.viphog_version}.tar.gz
    rm vpHMM_database_${params.viphog_version}.tar.gz
    """
}


 // roughly 3 GB size