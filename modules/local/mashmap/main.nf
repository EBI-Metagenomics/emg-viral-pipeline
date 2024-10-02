process MASHMAP {
    label 'process_medium'
    tag "${assembly_name}"
    container 'quay.io/microbiome-informatics/mashmap:2.0'

    input:
      tuple val(assembly_name), val(confidence_set_name), file(fasta) 
      file(reference)
    
    output:
      file("${confidence_set_name}_mashmap_hits.tsv")
    
    script:
    """
    sed -i "s/ /|/" ${fasta}
    mashmap -q ${fasta} -r ${reference} -t ${task.cpus} -o ${confidence_set_name}_mashmap_hits.tsv --noSplit -s ${params.mashmap_len}
    """
}
