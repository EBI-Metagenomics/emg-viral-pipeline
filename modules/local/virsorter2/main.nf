process VIRSORTER2 {

  tag "${meta.id}"

  label 'process_high'

  container 'quay.io/microbiome-informatics/virsorter:2.2.4_1'
  // container 'quay.io/biocontainers/virsorter:2.2.4--pyhdfd78af_2'

  input:
  tuple val(meta), file(fasta), val(number_of_contigs)
  path database

  output:
  tuple val(meta), path("*.final-viral-score.tsv"), emit: score_tsv
  tuple val(meta), path("*.final-viral-boundary.tsv"), emit: boundary_tsv
  tuple val(meta), path("*.final-viral-combined.fa"), emit: combined_fa

  when: number_of_contigs.toInteger() > 0

  script:
  def args = task.ext.args ?: ''
  """
  # Extract chunk number to rename output files
  filename=\$(basename ${fasta})
  # Extract VALUE (assuming the filename is in format NAME.VALUE.fasta)
  export value="all"
  value=\$(echo "\$filename" | cut -d'.' -f2)

  virsorter run \\
    --db-dir ${database} \\
    --use-conda-off \\
    --working-dir virsorter2 \\
    --seqfile ${fasta} \\
    --jobs ${task.cpus} \\
    ${args} \\
    all

  # Rename files
  mv virsorter2/final-viral-score.tsv "\${value}.final-viral-score.tsv"
  mv virsorter2/final-viral-boundary.tsv "\${value}.final-viral-boundary.tsv"
  mv virsorter2/final-viral-combined.fa "\${value}.final-viral-combined.fa"
  """
}
