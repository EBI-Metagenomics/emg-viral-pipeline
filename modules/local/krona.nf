process generate_krona_table {
      publishDir "${params.output}/${name}/${params.plotdir}", mode: 'copy', pattern: "*.krona.tsv"
      publishDir "${params.output}/${name}/${params.finaldir}/krona/", mode: 'copy', pattern: "*.krona.tsv"
      label 'python3'

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

process krona {
    publishDir "${params.output}/${name}/${params.plotdir}/krona/", mode: 'copy', pattern: "*.krona.html"
    publishDir "${params.output}/${name}/${params.finaldir}/krona/", mode: 'copy', pattern: "*.krona.html"
    label 'krona'  
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

/* Comments:
*/