process write_gff {
       publishDir "${params.output}/${name}/${params.finaldir}/gff", mode: 'copy' , pattern: "*.gff"
       publishDir "${params.output}/${name}/", mode: 'copy' , pattern: "metadata.tsv"

       errorStrategy 'ignore'
       label 'python3'
    input:
       tuple val(name), val(confidence_set_name), file(annotation)
       tuple val(name), val(confidence_set_name), file(quality_summary), path(quality)
       tuple val(name), val(confidence_set_name), file(taxonomy)
    output:
       tuple file("${name}_virify_contig_viewer_metadata.tsv"), file("${name}_virify.gff") optional false
    script:
    """
    write_viral_gff.py -v ${annotation} -c ${quality_summary} -t ${taxonomy} -s ${name}
    """
}