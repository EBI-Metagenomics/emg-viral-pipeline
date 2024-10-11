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
    first_file=\$(ls inputs | head -n 1);
    echo \${first_file}
    grep 'seqname' inputs/\${first_file} > header.tsv
    echo "1"
    cat inputs/* | grep -v 'seqname' > without_header.${output_name}
    echo "2"
    cat header.tsv without_header.${output_name} > ${output_name}
    echo "3"
    rm without_header.${output_name}
    echo "4"
    """
}