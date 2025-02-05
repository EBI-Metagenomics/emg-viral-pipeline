process SPLIT_PROTEINS {
    tag "${meta.id} ${fasta}"
    label 'process_single'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), val(confidence_set_name), path(fasta), path(proteins)
    
    output:
    tuple val(meta), val(confidence_set_name), path(fasta), path("*_split.faa")
    
    script:
    """    
    split_proteins_by_categories.py -i ${fasta} -o ${confidence_set_name}_split.faa -p ${proteins}
    """
}
