process pvogsGetDB {

  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'    
  
  publishDir "${params.databases}", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("pvogs", type: 'dir'), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O pvogs.tar.gz
    tar -zxvf pvogs.tar.gz
    rm pvogs.tar.gz
    """
}
