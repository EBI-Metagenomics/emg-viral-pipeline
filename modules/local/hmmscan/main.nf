process HMMSCAN {

    label 'process_high'
    
    container 'quay.io/microbiome-informatics/hmmer:3.1b2'
    
    input:
      tuple val(name), val(set_name), file(faa) 
      file(db)
    
    output:
      tuple val(name), val(set_name), file("${set_name}_${params.db}_hmmscan.tbl"), file(faa)
    
    script:
    """
    if [[ ${params.db} == "viphogs" ]]; then
      if [[ ${params.version} == "v1" ]]; then
        hmmscan --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${params.db}_hmmscan.tbl ${db}/${db}.hmm ${faa}
      else
        hmmscan --cpu ${task.cpus} --noali --cut_ga --domtblout ${set_name}_${params.db}_hmmscan_cutga.tbl ${db}/${db}.hmm ${faa}
        #filter evalue for models that dont have any GA cutoff
        awk '{if(\$1 ~ /^#/){print \$0}else{if(\$7<0.001){print \$0}}}' ${set_name}_${params.db}_hmmscan_cutga.tbl > ${set_name}_${params.db}_hmmscan.tbl
      fi
    else
      hmmscan --cpu ${task.cpus} --noali -E "0.001" --domtblout ${set_name}_${params.db}_hmmscan.tbl ${db}/${db}.hmm ${faa}
    fi
    """
}
