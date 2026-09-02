process vogdbGetDB {
  label 'process_low'
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

  publishDir "${params.databases}", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("vogdb", type: 'dir'), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O vogdb.tar.gz
    tar -zxvf vogdb.tar.gz
    rm vogdb.tar.gz
    """
}
