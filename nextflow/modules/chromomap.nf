process generate_chromomap_table {
      publishDir "${params.output}/${name}/${params.finaldir}/chromomap/", mode: 'copy', pattern: "${id}.filtered-*.contigs.txt"
      label 'ruby'

    input:
      tuple val(name), val(set_name), file(assembly), file(annotation_table)
    
    output:
      tuple val(name), val(set_name), file("${id}.filtered-*.contigs.txt"), file("${id}.filtered-*.anno.txt")
    
    shell:
    id = set_name
    if (set_name == "all") { id = name }
    """
    # combine
    if [[ ${set_name} == "all" ]]; then
      cat *.tsv | grep -v Abs_Evalue_exp | sort | uniq > ${id}.tsv
      cat *.fasta > ${id}.fasta
    else
      cp ${annotation_table} ${id}.tsv
      cp ${assembly} ${id}.fasta
    fi

    # now we remove contigs shorter 1500 kb and very long ones because ChromoMap has an error when plotting to distinct lenghts
    # we also split into multiple files when we have many contigs, chunk size default 30
    filter_for_chromomap.rb ${id}.fasta ${id}.tsv ${id}.contigs.txt ${id}.anno.txt 1500
    """
}

process chromomap {
    errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
    publishDir "${params.output}/${name}/${params.finaldir}/chromomap/", mode: 'copy', pattern: "*.html"
    label 'chromomap'

    input:
      tuple val(name), val(set_name), file(contigs), file(annotations)
    
    output:
      tuple val(name), val(set_name), file("*.html")
    
    shell:
    id = set_name
    if (set_name == "all") { id = name }
    """
    #!/usr/bin/env Rscript

    library(chromoMap)
    library(ggplot2)
    library(plotly)

    contigs <- list()
    annos <- list()
    contigs <- dir(pattern = "*.contigs.txt")
    annos <- dir(pattern = "*.anno.txt")

    for (k in 1:length(contigs)){
      c = contigs[k]
      a = annos[k]
      p <-  chromoMap(c, a,
        data_based_color_map = T,
        data_type = "categorical",
        data_colors = list(c("limegreen", "orange","grey")),
        legend = T, lg_y = 400, lg_x = 100, segment_annotation = T,
        left_margin = 100, canvas_width = 1000, chr_length = 8, ch_gap = 6)
      htmlwidgets::saveWidget(as_widget(p), paste("${id}.chromomap-", k, ".html", sep=''))
    }    
    """
}