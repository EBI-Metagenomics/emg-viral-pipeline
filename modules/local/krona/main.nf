process GENERATE_KRONA_TABLE {
    label 'process_single'
    tag "${meta.id} ${set_name}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'
    
    input:
      tuple val(meta), val(set_name), path(tbl)
    
    output:
      tuple val(meta), val(set_name), path("*.krona.tsv")
    
    script:
    """
    if [[ "${set_name}" == "all" ]]; then
      grep contig_ID *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq > ${meta.id}.tmp
      grep -v "contig_ID" *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq >> ${meta.id}.tmp
      cp ${meta.id}.tmp ${meta.id}.tsv
      generate_counts_table.py -f ${meta.id}.tsv -o ${meta.id}.krona.tsv
    else
      generate_counts_table.py -f ${tbl} -o ${set_name}.krona.tsv
    fi
    """
}

process KRONA {
    label 'process_low'  
    tag "${meta.id} ${set_name}"
    container 'quay.io/microbiome-informatics/krona:2.7.1'
    
    input:
      tuple val(meta), val(set_name), file(krona_file)
    output:
      file("*.krona.html")
      
    script:
      """
      if [[ ${set_name} == "all" ]]; then
        ktImportText -o ${meta.id}.krona.html ${krona_file}
      else
        ktImportText -o ${set_name}.krona.html ${krona_file}
      fi
      """
}
