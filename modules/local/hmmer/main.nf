process HMMER {
    tag "${meta.id} ${faa.baseName}"
    label 'process_high'
    
    container 'quay.io/microbiome-informatics/hmmer:3.1b2'
    
    input:
      tuple val(meta), val(set_name), path(faa) 
      path(db)
      val(is_viphog_db)
    
    output:
      tuple val(meta), val(set_name), path("${faa.baseName}_*_${params.hmmer_tool}.tbl")
    
    script:
    
    def execution_tool = params.hmmer_tool
    
    """
    if [ "${is_viphog_db}" == "true" ]; then
      if [ "${params.viphog_version}" == "v1" ]; then
        ${execution_tool} --cpu ${task.cpus} --noali -E "0.001" --domtblout ${faa.baseName}_${db.baseName}_${execution_tool}.tbl ${db}/${db}.hmm ${faa}
      else
        ${execution_tool} --cpu ${task.cpus} --noali --cut_ga --domtblout ${faa.baseName}_${db.baseName}_${execution_tool}_cutga.tbl ${db}/${db}.hmm ${faa}
        #filter evalue for models that dont have any GA cutoff
        awk '{if(\$1 ~ /^#/){print \$0}else{if(\$7<0.001){print \$0}}}' ${faa.baseName}_${db.baseName}_${execution_tool}_cutga.tbl > ${faa.baseName}_${db.baseName}_${execution_tool}.tbl
      fi
    else
      ${execution_tool} --cpu ${task.cpus} --noali -E "0.001" --domtblout ${faa.baseName}_${db.baseName}_${execution_tool}.tbl ${db}/${db}.hmm ${faa}
    fi
    """
}
