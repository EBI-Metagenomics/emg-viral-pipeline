process GENERATE_KRONA_TABLE {
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'
    
    input:
      tuple val(name), val(set_name), file(tbl)
    
    output:
      tuple val(name), val(set_name), file("*.krona.tsv")
    
    script:
    """
    if [[ "${set_name}" == "all" ]]; then
      grep contig_ID *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq > ${name}.tmp
      grep -v "contig_ID" *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq >> ${name}.tmp
      cp ${name}.tmp ${name}.tsv
      generate_counts_table.py -f ${name}.tsv -o ${name}.krona.tsv
    else
      generate_counts_table.py -f ${tbl} -o ${set_name}.krona.tsv
    fi
    """
}

process KRONA {
    label 'process_low'  
    
    container 'quay.io/microbiome-informatics/krona:2.7.1'
    
    input:
      tuple val(name), val(set_name), file(krona_file)
    output:
      file("*.krona.html")
      
    script:
      """
      if [[ ${set_name} == "all" ]]; then
        ktImportText -o ${name}.krona.html ${krona_file}
      else
        ktImportText -o ${set_name}.krona.html ${krona_file}
      fi
      """
}
