process RENAME_PRODIGAL {
    label 'process_single'
    tag "${meta.id}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(proteins_gff), path(proteins_faa)

    output:
    tuple val(meta), path("${meta.id}_renamed.gff"), emit: gff

    script:
    """
    rename_prodigal.py \
        -p ${proteins_faa} \
        -g ${proteins_gff} \
        -o ${meta.id}_renamed.gff
    """
}
