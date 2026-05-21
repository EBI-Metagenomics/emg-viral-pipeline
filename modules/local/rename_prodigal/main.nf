process RENAME_PRODIGAL {
    label 'process_single'
    tag "${meta.id} ${confidence_set_name}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), val(confidence_set_name), path(proteins_faa), path(proteins_gff)

    output:
    tuple val(meta), val(confidence_set_name), path("${confidence_set_name}_renamed.gff"), emit: gff

    script:
    """
    rename_prodigal.py \
        -p ${proteins_faa} \
        -g ${proteins_gff} \
        -o ${confidence_set_name}_renamed.gff
    """
}
