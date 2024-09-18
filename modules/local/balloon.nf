process balloon {
    publishDir "${params.output}/${name}/${params.finaldir}/balloon/", mode: 'copy', pattern: "*.{pdf,svg}"
    label 'balloon'

    input:
      tuple val(name), val(set_name), file(tbl)
    
    output:
      path ("*.{pdf,svg}") optional true
    
    script:
    """
    if [[ "${set_name}" == "all" ]]; then
      # concat all taxonomy results per assembly regardless of HC, LC or PP
      cat *_annotation_taxonomy.tsv | grep -v contig_ID > tmp.tsv
      NAME=all
    else
      cp ${tbl} tmp.tsv
      NAME=${set_name}
    fi

    # genus
    grep -v contig_ID tmp.tsv | awk -v SAMPLE="${name}" 'BEGIN{FS="\\t"};{if(\$2!="" && \$2 !~ /^0/){print SAMPLE"\\tgenus\\t"\$2}}' | sort | uniq -c | awk '{printf \$2"\\t"\$3"\\t"\$4"\\t"\$1"\\n"}' > \$NAME"_summary.tsv"

    # subfamily
    grep -v contig_ID tmp.tsv | awk -v SAMPLE="${name}" 'BEGIN{FS="\\t"};{if(\$3!="" && \$3 !~ /^0/){print SAMPLE"\\tsubfamily\\t"\$3}}' | sort | uniq -c | awk '{printf \$2"\\t"\$3"\\t"\$4"\\t"\$1"\\n"}' >> \$NAME"_summary.tsv"

    # family
    grep -v contig_ID tmp.tsv | awk -v SAMPLE="${name}" 'BEGIN{FS="\\t"};{if(\$4!="" && \$4 !~ /^0/){print SAMPLE"\\tfamily\\t"\$4}}' | sort | uniq -c | awk '{printf \$2"\\t"\$3"\\t"\$4"\\t"\$1"\\n"}' >> \$NAME"_summary.tsv"

    # order
    grep -v contig_ID tmp.tsv | awk -v SAMPLE="${name}" 'BEGIN{FS="\\t"};{if(\$5!="" && \$5 !~ /^0/){print SAMPLE"\\torder\\t"\$5}}' | sort | uniq -c | awk '{printf \$2"\\t"\$3"\\t"\$4"\\t"\$1"\\n"}' >> \$NAME"_summary.tsv"

    if [ -s \$NAME"_summary.tsv" ]; then
      balloon.R "\${NAME}_summary.tsv" "\${NAME}_balloon.svg" 10 8 
    fi
    """
}
