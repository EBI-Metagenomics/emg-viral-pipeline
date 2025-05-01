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
    [ -d "pprmeta" ] && cp pprmeta/* .
    ./PPR_Meta ${fasta} ${meta.id}_pprmeta.csv
    """
}

process PPRMETA_GETDB {

  // TODO: use a community supported image
  container 'nanozoo/template:3.8--ccd0653'

  label 'process_single'

  output:
  path "*"

  script:
  """
  git clone https://github.com/mult1fractal/PPR-Meta.git
  mv PPR-Meta/* .  
  rm -r PPR-Meta
  """
}
