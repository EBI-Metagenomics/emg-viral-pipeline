process MASHMAP {
    label 'process_medium'
    tag "${meta.id} ${confidence_set_name}"
    container 'quay.io/microbiome-informatics/mashmap:2.0'

    input:
      tuple val(meta), val(confidence_set_name), path(fasta) 
      path(reference)
    
    output:
      path("${confidence_set_name}_mashmap_hits.tsv")
    
    script:
    """
    sed -i "s/ /|/" ${fasta}
    mashmap -q ${fasta} -r ${reference} -t ${task.cpus} -o ${confidence_set_name}_mashmap_hits.tsv --noSplit -s ${params.mashmap_len}
    """
}
