process HMMSCAN {
    tag "${meta.id} ${set_name}"
    label 'process_high'
    
    container 'quay.io/microbiome-informatics/hmmer:3.1b2'
    
    input:
      tuple val(meta), val(set_name), path(faa) 
      path(db)
    
    output:
      tuple val(meta), val(set_name), path("${set_name}_*_hmmscan.tbl"), path(faa)
    
    script:
    """
    if [[ ${params.databases} == "viphogs" ]]; then
      if [[ ${params.version} == "v1" ]]; then
        hmmscan --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${db.baseName}_hmmscan.tbl ${db}/${db}.hmm ${faa}
      else
        hmmscan --cpu ${task.cpus} --noali --cut_ga --domtblout ${set_name}_${db.baseName}_hmmscan_cutga.tbl ${db}/${db}.hmm ${faa}
        #filter evalue for models that dont have any GA cutoff
        awk '{if(\$1 ~ /^#/){print \$0}else{if(\$7<0.001){print \$0}}}' ${set_name}_${db.baseName}_hmmscan_cutga.tbl > ${set_name}_${db.baseName}_hmmscan.tbl
      fi
    else
      hmmscan --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${db.baseName}_hmmscan.tbl ${db}/${db}.hmm ${faa}
    fi
    """
}
