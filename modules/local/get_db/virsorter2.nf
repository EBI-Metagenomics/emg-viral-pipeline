process virsorter2GetDB {
  label 'virsorter2'

  publishDir "${params.databases}", pattern: "virsorter2-data", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("virsorter2-data/db", type: 'dir'), emit: database_dir

  script:
    """
    # just in case there is a failed attemp before;
    # remove the whole diretory specified by -d
    rm -rf virsorter2-data

    # download virsorter2 database and extract
    wget -nH ${db_link} -O virsorter2-download
    mkdir virsorter2-data
    tar -xzf virsorter2-download -C virsorter2-data
    """
}
