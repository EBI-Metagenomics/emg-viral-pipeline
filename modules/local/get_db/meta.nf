process metaGetDB {
    label 'process_low'    
    container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
    publishDir "${params.databases}/models", pattern: "additional_data_vpHMMs_${params.meta_version}.tsv", mode: params.cloudProcess ? 'copy' : 'symlink'
       
    output:
      file("additional_data_vpHMMs_${params.meta_version}.tsv")
    
    script:
    """
    echo "Downloading ${params.meta_version} of the metadata"
    wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/additional_data_vpHMMs_${params.meta_version}.tsv
    """
}