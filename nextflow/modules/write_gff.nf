process write_gff {
    publishDir "${params.output}/${name}/${params.finaldir}/gff", mode: 'copy' , pattern: "*.gff"

    //errorStrategy 'ignore'
    label 'python3'

    input:
       tuple val(name), file(fasta)
       path 'high_confidence_viral_contigs_prodigal_annotation*.tsv'
       path 'high_confidence_viral_contigs_prodigal_annotation_taxonomy*.tsv'
       path 'prophages_quality_summary*.tsv'

    output:
       file("${name}_virify.gff")

    script:
    """
    write_viral_gff.py \
    -v high_confidence_viral_contigs_prodigal_annotation* \
    -c prophages_quality_summary* \
    -t high_confidence_viral_contigs_prodigal_annotation_taxonomy* \
    -s ${name} \
    -a ${fasta}

    gt gff3validator ${name}_virify.gff
    """
}
