process PPRMETA {
  label 'process_medium'
  tag "${meta.id}"
  container 'quay.io/microbiome-informatics/pprmeta:1.1'

  input:
  tuple val(meta), path(fasta), val(contig_number)
  path pprmeta_git

  output:
  tuple val(meta), path("${meta.id}_pprmeta.csv")

  when:
  contig_number.toInteger() > 0

  script:
  """
  export MCR_CACHE_ROOT="\$(pwd)/mcr_cache_root"
  mkdir -p \$(pwd)/mcr_cache_root

  [ -d "pprmeta" ] && cp pprmeta/* .
  ./PPR_Meta ${fasta} ${meta.id}_pprmeta.csv
  """
}

process pprmetaGet {

  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'

  label 'process_single'

  output:
  path "*"

  script:
  """
  wget -nH https://github.com/zhenchengfang/PPR-Meta/archive/refs/tags/v1.1.tar.gz
  tar -xzf v1.1.tar.gz && rm v1.1.tar.gz
  mv PPR-Meta-1.1/* .
  chmod +xr *
  rm -r PPR-Meta-1.1
  """
}
