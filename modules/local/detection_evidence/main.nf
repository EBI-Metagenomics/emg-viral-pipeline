/*
 * Join the detection calls of PARSE with the VirFinder, PPR-Meta and CheckV values.
 * One row per HC, LC or PP sequence, with the short contig names of the GFF.
 * Contigs that VIRify did not call are not in the table.
 */
process DETECTION_EVIDENCE {
    tag "${meta.id}"
    label 'process_single'

    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(calls), path(virfinder), path(pprmeta), path(mapfile), path(quality_summaries, stageAs: "checkv/*")

    output:
    tuple val(meta), path("${meta.id}_detection_evidence.tsv"), emit: tsv

    script:
    // A sample whose categories all lost their proteins has no CheckV results
    def checkv_arg = quality_summaries ? "--checkv ${quality_summaries}" : ""
    """
    write_detection_evidence.py \\
      --calls ${calls} \\
      --virfinder ${virfinder} \\
      --pprmeta ${pprmeta} \\
      --map ${mapfile} \\
      ${checkv_arg} \\
      --output ${meta.id}_detection_evidence.tsv
    """

    stub:
    """
    touch ${meta.id}_detection_evidence.tsv
    """
}
