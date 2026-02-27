process WRITE_GFF {
    tag "${meta.id}"
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'
    
    input:
    tuple val(meta), path(fasta), path(viphos_annotations), path(taxonomies), path(quality_summaries)

    output:
    tuple val(meta), path("${meta.id}_virify.gff"), emit: gff

    script:
    def use_proteins_flag = params.use_proteins ? "--use-proteins": "" ;
    """
    write_viral_gff.py \\
      $use_proteins_flag \\
      -v ${viphos_annotations.join(' ')} \\
      -c ${quality_summaries.join(' ')} \\
      -t ${taxonomies.join(' ')} \\
      -s ${meta.id} \\
      -a ${fasta}

    gt gff3validator ${meta.id}_virify.gff
    """
}
