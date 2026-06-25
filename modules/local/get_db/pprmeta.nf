process pprmetaGet {
    label 'process_single'
    container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

    publishDir "${params.pprmeta}", mode: params.cloudProcess ? 'copy' : 'symlink'

    output:
    path ("pprmeta", type: 'dir')

    script:
    """
    wget -nH https://github.com/zhenchengfang/PPR-Meta/archive/refs/tags/v1.1.tar.gz
    tar -xzf v1.1.tar.gz && rm v1.1.tar.gz
    mv PPR-Meta-1.1/* .
    chmod +xr *
    rm -r PPR-Meta-1.1
    """
}
