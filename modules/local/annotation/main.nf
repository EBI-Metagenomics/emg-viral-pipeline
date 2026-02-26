process ANNOTATION {
    /*
     * Generate tabular file with ViPhOG annotation results for 
     * proteins predicted in viral contigs
    */
    tag "${meta.id} ${set_name}"

    label 'process_single'

    container 'quay.io/microbiome-informatics/virify-python3:1.1'

    input:
    tuple val(meta), val(set_name), path(tab), path(faa)

    output:
    tuple val(meta), val(set_name), path("*_annotation.tsv"), emit: annotations

    script:
    """
    viral_contigs_annotation.py -o . -p ${faa} -t ${tab}
    """
}
