process PPRMETA {
  label 'process_medium'
  tag "${meta.id}"
  container 'quay.io/microbiome-informatics/pprmeta:1.1'

  input:
  tuple val(meta), path(fasta)
  tuple val(meta_db), path(pprmeta_git)

  output:
  tuple val(meta), path("${meta.id}.${fasta.baseName}_pprmeta.csv"), emit: result_csv

  when:
  fasta.size() > 0

  script:
  """
  export MCR_CACHE_ROOT="\$(pwd)/mcr_cache_root"
  mkdir -p \$(pwd)/mcr_cache_root

  [ -d "pprmeta" ] && cp pprmeta/* .
  ./PPR_Meta ${fasta} ${meta.id}.${fasta.baseName}_pprmeta.csv
  """
}
