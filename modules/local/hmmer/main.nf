process HMMER {
  tag "${meta.id} ${faa.baseName}"
  label 'process_high'

  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
      'https://depot.galaxyproject.org/singularity/hmmer:3.4--hdbdd923_1' :
      'biocontainers/hmmer:3.4--hdbdd923_1' }"

  input:
  tuple val(meta), val(set_name), path(faa)
  path db
  val is_viphog_db

  output:
  tuple val(meta), val(set_name), path("${faa.baseName}_*_${params.hmmer_tool}.tbl")

  script:
  def execution_tool = params.hmmer_tool;
  def out_prefix = "${faa.baseName}_${db.baseName}_${execution_tool}";
  def hmm_size = ""
  if ( execution_tool == "hmmsearch" ) {
    // E-values are dependent on the DB size, for hmmsearch the DB is the faa
    // So, in order to have comparable e-values (to hmmscan), we need to use -Z to force
    // hmmsearch to normalize the e-values based on the hmm db size
    hmm_size = "-Z \$(hmmstat ${db}/${db}.hmm | grep -v \"#\" | wc -l)"
  }
  """
    if [ "${is_viphog_db}" == "true" ]; then
      if [ "${params.viphog_version}" == "v1" ]; then
        ${execution_tool} \\
          --cpu ${task.cpus} \\
          --noali -E "0.001" \\
          --domtblout ${out_prefix}.tbl \\
          ${hmm_size} \\
          ${db}/${db}.hmm ${faa}
      else
        ${execution_tool} \\
          --cpu ${task.cpus} \\
          --noali \\
          --cut_ga \\
          --domtblout ${out_prefix}_cutga.tbl \\
          ${hmm_size} \\
          ${db}/${db}.hmm ${faa}

        # filter evalue for models that dont have any GA cutoff
        awk '{if(\$1 ~ /^#/){print \$0}else{if(\$7<0.001){print \$0}}}' ${out_prefix}_cutga.tbl > ${out_prefix}.tbl
      fi
    else
      ${execution_tool} \\
        --cpu ${task.cpus} \\
        --noali -E "0.001" \\
        --domtblout ${out_prefix}.tbl \\
        ${hmm_size} \\
        ${db}/${db}.hmm ${faa}
    fi
    """
}
