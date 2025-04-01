process HMMSEARCH {
    tag "${meta.id} ${set_name}"
    label 'process_high'
    
    container 'quay.io/microbiome-informatics/hmmer:3.1b2'
    
    input:
      tuple val(meta), val(set_name), path(faa) 
      path(db)
    
    output:
      tuple val(meta), val(set_name), path("${set_name}_*_hmmsearch.tbl"), path(faa)
    
    script:
    """
    if [[ ${params.databases} == "viphogs" ]]; then
      if [[ ${params.version} == "v1" ]]; then
        hmmsearch --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${db.baseName}_hmmsearch.tbl ${db}/${db}.hmm ${faa}
      else
        hmmsearch --cpu ${task.cpus} --noali --cut_ga --domtblout ${set_name}_${db.baseName}_hmmsearch_cutga.tbl ${db}/${db}.hmm ${faa}
        #filter evalue for models that dont have any GA cutoff
        awk '{if(\$1 ~ /^#/){print \$0}else{if(\$7<0.001){print \$0}}}' ${set_name}_${db.baseName}_hmmsearch_cutga.tbl > ${set_name}_${db.baseName}_hmmsearch.tbl
      fi
    else
      hmmsearch --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${db.baseName}_hmmsearch.tbl ${db}/${db}.hmm ${faa}
    fi
    """
}
