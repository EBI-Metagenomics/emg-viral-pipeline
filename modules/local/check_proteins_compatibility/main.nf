process CHECK_PROTEINS_COMPATIBILITY {
    label 'process_single'
    tag "${meta.id}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(fasta), path(proteins_gff), path(proteins_faa)

    output:
    tuple val(meta), path("results/*"), emit: status

    script:
    """
    check_proteins_compatibility.py \
        --fasta ${fasta} \
        --proteins-faa ${proteins_faa} \
        --proteins-gff ${proteins_gff} \
        --output-dir results
    """
}
