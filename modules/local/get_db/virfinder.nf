process virfinderGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  publishDir "${params.databases}", pattern: "VF.modEPV_k8.rda", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("VF.modEPV_k8.rda"), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O VF.modEPV_k8.rda
    """
}
