
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
    """
    echo "Downloading ${params.meta_version} of the metadata"
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/additional_data_vpHMMs_${params.meta_version}.tsv
    """
}