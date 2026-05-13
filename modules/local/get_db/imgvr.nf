process imgvrGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10' 
  
  publishDir "${params.databases}/imgvr", pattern: "IMG_VR_2018-07-01_4", mode: params.cloudProcess ? 'copy' : 'symlink'

  output:
    path("IMG_VR_2018-07-01_4", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/IMG_VR_2018-07-01_4.tar.gz && tar zxvf IMG_VR_2018-07-01_4.tar.gz
    """
}
