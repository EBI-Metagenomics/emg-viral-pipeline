process SPLIT_PROTEINS {
    tag "${meta.id} ${fasta}"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' ?
                'oras://community.wave.seqera.io/library/pip_biopython:746a711789280f4a' :
                'community.wave.seqera.io/library/pip_biopython:702fef869ad99456' }"

    input:
    tuple val(meta), val(confidence_set_name), path(fasta), path(proteins_gff), path(proteins_faa)

    output:
    tuple val(meta), val(confidence_set_name), path(fasta), path("${confidence_set_name}_split.faa"), path("${confidence_set_name}_split.gff"), emit: fasta_proteins_gff
    tuple val(meta), val(confidence_set_name), path("${confidence_set_name}_no_proteins.tsv")       , emit: dropped_report

    script:
    def fasta_file = fasta.name.endsWith('.gz') ? fasta.baseName : fasta.name
    def proteins_file_faa = proteins_faa.name.endsWith('.gz') ? proteins_faa.baseName : proteins_faa.name
    def proteins_file_gff = proteins_gff.name.endsWith('.gz') ? proteins_gff.baseName : proteins_gff.name
    """
    if [[ ${fasta} == *.gz ]]; then
        gunzip -c ${fasta} > ${fasta_file}
    fi
    if [[ ${proteins_faa} == *.gz ]]; then
        gunzip -c ${proteins_faa} > ${proteins_file_faa}
    fi
    if [[ ${proteins_gff} == *.gz ]]; then
        gunzip -c ${proteins_gff} > ${proteins_file_gff}
    fi

    split_proteins_by_categories.py \\
        -i ${fasta_file} \\
        -o ${confidence_set_name}_split.faa \\
        -p ${proteins_file_faa} \\
        -g ${proteins_file_gff} \\
        --output-gff ${confidence_set_name}_split.gff \\
        --dropped-report ${confidence_set_name}_no_proteins.tsv
    """
}
