process LENGTH_FILTERING {

    /*
     * Extract sequences at least X kb long
    */

    label 'process_single'
    tag "${meta.id}"

    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/biopython:1.84' :
        'quay.io/biocontainers/biopython:1.84' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_filtered.fasta")

    script:
    """
    filter_contigs_len.py -f ${fasta} -l ${params.length} -o ./
    mv *_filt*.fasta ${meta.id}_filtered.fasta
    """
}
