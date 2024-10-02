process PHANOTATE {
    label 'process_low'
    tag "${name}"
    container 'quay.io/biocontainers/phanotate:1.5.0--h30d9df9_2'
    
    input:
      tuple val(name), file(fasta) 
    
    output:
      tuple val(name), stdout, file("*.faa")
    
    script:
    """
    # this can be removed as soon as a conda recipe is available
    git clone https://github.com/deprekate/PHANOTATE.git
    cd PHANOTATE 
    git clone https://github.com/deprekate/fastpath.git
    make

    BN=\$(basename ${fasta} .fna)
    phanotate.py -f fasta -o \${BN}_phanotate.fna ../${fasta} > /dev/null
    transeq -sequence \${BN}_phanotate.fna -outseq \${BN}_phanotate.faa > /dev/null
    cp \${BN}_phanotate.faa ../
    printf "\$BN"
    """
}
