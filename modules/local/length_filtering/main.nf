process LENGTH_FILTERING {

    /*
     * Extract sequences at least X kb long
    */

    label 'process_single'
    tag "${meta.id}"

    container 'quay.io/biocontainers/biopython:1.75'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_filtered.fasta"), env(CONTIGS)

    script:
    """
    filter_contigs_len.py -f ${fasta} -l ${params.length} -o ./
    mv *_filt*.fasta ${meta.id}_filtered.fasta
    CONTIGS=\$(grep ">" ${meta.id}_filtered.fasta | wc -l)
    """
}
