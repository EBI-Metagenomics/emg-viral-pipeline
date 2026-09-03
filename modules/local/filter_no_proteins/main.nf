process FILTER_NO_PROTEINS {

    /*
     * Discard contigs with no CDS in the proteins GFF, before the viral prediction tools.
     *
     * The assembly is in the temporary name space (seq1, seq2, ...) that DETECT consumes,
     * while the proteins GFF is in the short name space, so the rename mapping is needed
     * to relate the two.
    */

    label 'process_single'
    tag "${meta.id}"

    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/biopython:1.84' :
        'quay.io/biocontainers/biopython:1.84' }"

    input:
    tuple val(meta), path(fasta), path(mapfile), path(proteins_gff)

    output:
    tuple val(meta), path("${meta.id}_with_proteins.fasta"), emit: filtered_fasta
    tuple val(meta), path("${meta.id}_no_proteins.tsv")    , emit: dropped_report

    script:
    def proteins_file_gff = proteins_gff.name.endsWith('.gz') ? proteins_gff.baseName : proteins_gff.name
    """
    if [[ ${proteins_gff} == *.gz ]]; then
        gunzip -c ${proteins_gff} > ${proteins_file_gff}
    fi

    filter_contigs_no_proteins.py \\
        -i ${fasta} \\
        -m ${mapfile} \\
        -g ${proteins_file_gff} \\
        -o ${meta.id}_with_proteins.fasta \\
        --dropped-report ${meta.id}_no_proteins.tsv
    """
}
