process viphogGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'   
  
  publishDir "${params.databases}/", pattern: "vpHMM_database_${params.viphog_version}", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("vpHMM_database_${params.viphog_version}", type: 'dir'), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O vpHMM_database_${params.viphog_version}.tar.gz
    tar -zxvf vpHMM_database_${params.viphog_version}.tar.gz
    rm vpHMM_database_${params.viphog_version}.tar.gz
    """
}


 // roughly 3 GB size
