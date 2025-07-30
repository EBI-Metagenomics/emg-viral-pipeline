process RESTORE {
    /*
    usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
    */
    tag "${meta.id} ${fasta}"
    label 'process_single'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(fasta), path(map) 
    val from_restore
    val to_restore
    
    output:
    tuple val(meta), env(BN), path("*_original.fasta")
    
    script:
    """    
    BN=\$(basename ${fasta} .fna)
    rename_fasta.py -i ${fasta} -m ${map} -o \${BN}_original.fasta restore --from-restore "${from_restore}" --to-restore "${to_restore}" 
    """
}


