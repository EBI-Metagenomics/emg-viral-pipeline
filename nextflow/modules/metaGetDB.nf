
process metaGetDB {
  label 'noDocker'
  if (params.cloudProcess) { 
    publishDir "${params.databases}/models", mode: 'copy', pattern: "additional_data_vpHMMs_${params.meta_version}.tsv" 
  }
  else { 
    storeDir "${params.databases}/models" 
  }  
    
    output:
      file("additional_data_vpHMMs_${params.meta_version}.tsv")
    
    script:
    if (params.meta_version.toString() == 'v1')
    """
    # v1 of metadata file
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/additional_data_vpHMMs_v1.tsv
    """
    else if (params.meta_version.toString() == 'v2')
    """
    # v2 of metadata file
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/additional_data_vpHMMs_v2.tsv
    """
    
}