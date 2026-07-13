process VIRFINDER {

  tag "${meta.id}"

  label 'process_medium'

  container 'quay.io/microbiome-informatics/virfinder:1.1__eb8032e'

  input:
  tuple val(meta), path(fasta)
  path model

  output:
  tuple val(meta), path("${meta.id}.${fasta.baseName}.txt"), emit: result_tsv

  when:
  fasta.countFasta() > 0

  script:
  """
  run_virfinder.Rscript ${model} ${fasta} .
  awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$4}' ${meta.id}*.tsv > ${meta.id}.${fasta.baseName}.txt
  """
}
