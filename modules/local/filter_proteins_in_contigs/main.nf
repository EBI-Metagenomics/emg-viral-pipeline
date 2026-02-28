process FILTER_PROTEINS_IN_CONTIGS {
    /*
     * Keep only proteins whose parent contig is present in the given
     * contigs FASTA (e.g. after length filtering).
    */

    label 'process_single'
    tag "${meta.id}"

    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(proteins), path(contigs)

    output:
    tuple val(meta), path("${meta.id}_filtered.faa")

    script:
    def proteins_file = proteins.name.endsWith('.gz') ? proteins.baseName : proteins.name
    """
    if [[ ${proteins} == *.gz ]]; then
        gunzip -c ${proteins} > ${proteins_file}
    fi

    filter_proteins_in_contigs.py \\
        --proteins ${proteins_file} \\
        --contigs ${contigs} \\
        --output ${meta.id}_filtered.faa
    """
}
