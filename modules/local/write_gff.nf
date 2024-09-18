process WRITE_GFF {

    publishDir "${params.output}/${name}/${params.finaldir}/gff", mode: 'copy' , pattern: "*.gff"

    errorStrategy 'ignore'
    label 'python3'

    input:
    tuple val(name), path(fasta)
    path(viphos_annotations)
    path(taxonomies)
    path(quality_summaries)

    output:
    path("${name}_virify.gff")

    script:
    """
    write_viral_gff.py \
    -v ${viphos_annotations.join(' ')} \
    -c ${quality_summaries.join(' ')} \
    -t ${taxonomies.join(' ')} \
    -s ${name} \
    -a ${fasta}

    gt gff3validator ${name}_virify.gff
    """
}
