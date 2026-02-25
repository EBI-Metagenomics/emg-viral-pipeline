process SPLIT_PROTEINS {
    tag "${meta.id} ${fasta}"
    label 'process_single'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), val(confidence_set_name), path(fasta), path(proteins)
    
    output:
    tuple val(meta), val(confidence_set_name), path(fasta), path("*_split.faa")
    
    script:
    def fasta_file = fasta.name.endsWith('.gz') ? fasta.baseName : fasta.name
    def proteins_file = proteins.name.endsWith('.gz') ? proteins.baseName : proteins.name
    """
    if [[ ${fasta} == *.gz ]]; then
        gunzip -c ${fasta} > ${fasta_file}
    fi
    if [[ ${proteins} == *.gz ]]; then
        gunzip -c ${proteins} > ${proteins_file}
    fi
    
    split_proteins_by_categories.py -i ${fasta_file} -o ${confidence_set_name}_split.faa -p ${proteins_file}
    """
}