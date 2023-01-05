process write_gff {
    publishDir "${params.output}/${name}/${params.finaldir}/gff", mode: 'copy' , pattern: "*.gff"
    publishDir "${params.output}/${name}/${params.finaldir}/gff", mode: 'copy' , pattern: "*metadata.tsv"

    errorStrategy 'ignore'
    label 'python3'

    input:
       val(name)
       path(viphos_annotations)
       path(taxonomies)
       path(quality_summaries)

    output:
       tuple file("${name}_virify_contig_viewer_metadata.tsv"), file("${name}_virify.gff")

    script:
    """
    write_viral_gff.py \
    -v ${viphos_annotations.join(' ')} \
    -c ${quality_summaries.join( ' ' )} \
    -t ${taxonomies.join( ' ' )} \
    -s ${name}
    """
}