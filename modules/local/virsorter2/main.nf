process VIRSORTER2 {
    tag "${meta.id}"
    label 'process_medium'
    container 'docker://jiarong/virsorter:2.2.3'
    
    input:
      tuple val(meta), file(fasta), val(contig_number) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("virsorter2/*.{tsv,fa*}")

    script:
      """
      virsorter run -w virsorter2 -i ${fasta}  -j ${task.cpus} all
      """
}