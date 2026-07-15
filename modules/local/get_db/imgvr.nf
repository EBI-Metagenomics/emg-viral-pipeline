process imgvrGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10' 
  
  publishDir "${params.databases}", pattern: "IMG_VR_2018-07-01_4", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("IMG_VR_2018-07-01_4", type: 'dir'), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O IMG_VR_2018-07-01_4.tar.gz
    tar zxvf IMG_VR_2018-07-01_4.tar.gz
    rm IMG_VR_2018-07-01_4.tar.gz
    """
}
