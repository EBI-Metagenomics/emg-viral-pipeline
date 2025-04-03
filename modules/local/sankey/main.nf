process GENERATE_SANKEY_TABLE {
    label 'process_low'
    tag "${meta.id} ${set_name}"    
    container 'quay.io/microbiome-informatics/bioruby:2.0.1'

    input:
      tuple val(meta), val(set_name), path(krona_table)
    
    output:
      tuple val(meta), val(set_name), path("${set_name}.sankey.filtered-${params.sankey}.json"), path("${set_name}.sankey.tsv")
    
    script:
    """
    krona_table_2_sankey_table.rb ${krona_table} ${set_name}.sankey.tsv
    
    # select the top ${params.sankey} hits with highest count because otherwise sankey gets messy
    sort -k1,1nr ${set_name}.sankey.tsv | head -${params.sankey} > ${set_name}.sankey.filtered.tsv

    tsv2json.rb ${set_name}.sankey.filtered.tsv ${set_name}.sankey.filtered-${params.sankey}.json
    """
}

process SANKEY {

    label 'process_low'
    tag "${meta.id} ${set_name}"
    container 'quay.io/microbiome-informatics/sankeyd3:0.12.3'

    input:
      tuple val(meta), val(set_name), path(json), path(tsv)
    
    output:
      tuple val(meta), val(set_name), path("*.sankey.html")
    
    script:
    id = set_name
    if (set_name == "all") { id = meta.id }
    """
    #!/usr/bin/env Rscript

    library(sankeyD3)
    library(magrittr)

    Taxonomy <- jsonlite::fromJSON("${json}")

    # print to HTML file
    sankey = sankeyNetwork(Links = Taxonomy\$links, Nodes = Taxonomy\$nodes, Source = "source", Target = "target", Value = "value", NodeID = "name", units = "count", fontSize = 22, nodeWidth = 30, nodeShadow = TRUE, nodePadding = 30, nodeStrokeWidth = 1, nodeCornerRadius = 10, dragY = TRUE, dragX = TRUE, numberFormat = ",.3g", align = "left", orderByPath = TRUE)
    saveNetwork(sankey, file = '${id}.sankey.html')
    """
}