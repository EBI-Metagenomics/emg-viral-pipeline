process CONCATENATE_FILES {
    tag "${meta.id}"
    label "process_medium"

    input:
    tuple val(meta), path(input_files, stageAs: "inputs/*")
    val output_name

    output:
    tuple val(meta), path("${output_name}"), emit: concatenated_result

    script:
    """
    export first_file=\$(ls inputs | head -n 1);
    grep 'seqname' inputs/\${first_file} > header.tsv || true
    cat inputs/* | grep -v 'seqname' > without_header.${output_name}
    cat header.tsv without_header.${output_name} > ${output_name}
    rm without_header.${output_name}
    """
}