process restore {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "*_original.fasta"
      publishDir "${params.output}/${name}/${params.finaldir}/contigs/", mode: 'copy', pattern: "*_original.fasta"
      label 'python3'

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

/*
usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
*/
