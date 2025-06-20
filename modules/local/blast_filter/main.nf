process BLAST_FILTER {

  label 'process_single'

  tag "${meta.id} ${confidence_set_name}"

  container 'quay.io/microbiome-informatics/virify-python3:1.2'

  input:
  tuple val(meta), val(confidence_set_name), path(blast), path(blast_filtered)
  path db

  output:
  tuple val(meta), val(confidence_set_name), path("*.meta")

  script:
  """
  imgvr_merge.py -f ${blast_filtered} -d ${db}/IMGVR_all_Sequence_information.tsv -o \$(basename ${blast_filtered} .blast).meta
  """
}
