process virsorterGetDB {
  label 'process_low'
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

  publishDir "${params.databases}", pattern: "virsorter-data", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("virsorter-data", type: 'dir'), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O virsorter-data.tar.gz
    tar -xvzf virsorter-data.tar.gz
    rm virsorter-data.tar.gz
    """
}


 // roughly 4 GB size
