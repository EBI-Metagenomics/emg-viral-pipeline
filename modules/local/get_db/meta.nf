process metaGetDB {
    label 'process_low'
    container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

    publishDir "${params.databases}", pattern: "additional_data_vpHMMs_${params.meta_version}.tsv", mode: params.cloudProcess ? 'copy' : 'symlink'

    input:
    tuple val(meta), val(db_link)

    output:
      tuple val(meta), path("additional_data_vpHMMs_${params.meta_version}.tsv"), emit: database_dir

    script:
    """
    echo "Downloading ${params.meta_version} of the metadata"
    wget -nH ${db_link} -O additional_data_vpHMMs_${params.meta_version}.tsv
    """
}
