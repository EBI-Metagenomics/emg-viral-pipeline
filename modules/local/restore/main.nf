process RESTORE {
    /*
    usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
    */
    tag "${name}"
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(name), file(fasta), file(map) 
    
    output:
    tuple val(name), env(BN), file("*_original.fasta")
    
    script:
    """    
    BN=\$(basename ${fasta} .fna)
    rename_fasta.py -i ${fasta} -m ${map} -o \${BN}_original.fasta restore 2> /dev/null
    """
}


