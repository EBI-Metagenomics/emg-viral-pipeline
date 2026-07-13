process ncbiGetDB {
  label 'process_low'    
  container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
  
  publishDir "${params.databases}", pattern: "ete3_ncbi_tax.sqlite", mode: params.cloudProcess ? 'copy' : 'symlink'

  input:
  tuple val(meta), val(db_link)

  output:
    tuple val(meta), path("ete3_ncbi_tax.sqlite"), emit: database_dir

  script:
    """
    wget -nH ${db_link} -O ncbi_tax.sqlite.gz
    gunzip -f ncbi_tax.sqlite.gz
    mv ncbi_tax.sqlite ete3_ncbi_tax.sqlite
    """
}
