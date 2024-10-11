process CONCATENATE_FILES {
    tag "${meta.id}"

    input:
    tuple val(meta), path(input_files, stageAs: "inputs/*")
    val output_name

    output:
    tuple val(meta), path("${output_name}"), emit: concatenated_result

    script:
    """
    cat inputs/* > ${output_name}
    """
}