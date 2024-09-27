process SPADES {

  label 'process_medium'  
  
  container 'quay.io/biocontainers/spades:3.15.5--h95f258a_1'

  input:
    tuple val(name), file(reads)
  output:
    tuple val(name), file("${name}.fasta")
    
  script:
  """
    spades.py --meta --only-assembler -1 !{reads[0]} -2 !{reads[1]} -t !{task.cpus} -o assembly
    mv assembly/contigs.fasta !{name}.fasta
  """
}