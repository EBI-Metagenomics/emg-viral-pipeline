process spades {
    label 'spades'  
    publishDir "${params.output}/${name}/${params.assemblydir}", mode: 'copy', pattern: "${name}.fasta"
  input:
    tuple val(name), file(reads)
  output:
    tuple val(name), file("${name}.fasta")
  shell:
    '''
    spades.py --meta --only-assembler -1 !{reads[0]} -2 !{reads[1]} -t !{task.cpus} -o assembly
    mv assembly/contigs.fasta !{name}.fasta
    '''
  }

/* Comments:
*/