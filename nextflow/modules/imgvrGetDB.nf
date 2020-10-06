process imgvrGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/imgvr/", mode: 'copy', pattern: "IMG_VR_2018-07-01_4" 
  }
  else { 
    storeDir "${params.databases}/imgvr/" 
  }  
  output:
    path("IMG_VR_2018-07-01_4", type: 'dir')

  script:
    """
    wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/IMG_VR_2018-07-01_4.tar.gz && tar zxvf IMG_VR_2018-07-01_4.tar.gz
    """
}
