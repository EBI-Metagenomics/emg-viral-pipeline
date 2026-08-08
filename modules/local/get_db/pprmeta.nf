process pprmetaGet {
    label 'process_single'
    container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

    publishDir "${params.databases}", mode: params.cloudProcess ? 'copy' : 'symlink'

    input:
    tuple val(meta), val(db_link)

    output:
    tuple val(meta), path("pprmeta"), emit: database_dir

    script:
    """
    wget -nH ${db_link}
    tar -xzf v*.*.tar.gz && rm v*.*.tar.gz
    mkdir -p pprmeta
    mv PPR-Meta-*.*/* pprmeta
    chmod -R +xr pprmeta
    rm -r PPR-Meta-*.*
    """
}
