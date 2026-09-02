process WRITE_GFF {
    tag "${meta.id}"
    label 'process_low'

    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(fasta), path(viphos_annotations), path(taxonomies), path(quality_summaries), path(category_gffs)

    output:
    tuple val(meta), path("${meta.id}_virify.gff"), emit: gff

    script:
    """
    write_viral_gff.py \\
      -v ${viphos_annotations.join(' ')} \\
      -c ${quality_summaries.join(' ')} \\
      -t ${taxonomies.join(' ')} \\
      -s ${meta.id} \\
      -a ${fasta} \\
      -g ${category_gffs.join(' ')}

    gt gff3validator ${meta.id}_virify.gff
    """
}
