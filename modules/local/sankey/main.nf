process GENERATE_SANKEY_TABLE {
    label 'process_low'
    tag "${meta.id} ${set_name}"    
    container 'quay.io/microbiome-informatics/bioruby:2.0.1'

    input:
      tuple val(meta), val(set_name), path(krona_table)
    
    output:
      tuple val(meta), val(set_name), path("${set_name}.sankey.filtered-${params.sankey}.json"), emit: sankey_filtered_json
      tuple val(meta), val(set_name), path("${set_name}.sankey.filtered.tsv"),                   emit: sankey_filtered_tsv
    
    script:
    """
    krona_table_2_sankey_table.rb ${krona_table} ${set_name}.sankey.tsv
    
    # select the top ${params. } hits with highest count because otherwise sankey gets messy
    sort -k1,1nr ${set_name}.sankey.tsv | head -${params.sankey} > ${set_name}.sankey.filtered.tsv

    tsv2json.rb ${set_name}.sankey.filtered.tsv ${set_name}.sankey.filtered-${params.sankey}.json
    """
}

process SANKEY {

    label 'process_low'
    tag "${meta.id} ${set_name}"
    container 'quay.io/microbiome-informatics/sankeyd3:0.12.3'

    input:
      tuple val(meta), val(set_name), path(json)
    
    output:
      tuple val(meta), val(set_name), path("*.sankey.html")
    
    script:
    
    """
    sankey_html.R ${json} "${meta.id}.${set_name}.sankey.html"
    """
}