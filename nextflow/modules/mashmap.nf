process mashmap {
      label 'mashmap'

      publishDir "${params.output}/${assembly_name}/", mode: 'copy', pattern: "*.tsv"
      publishDir "${params.output}/${assembly_name}/${params.finaldir}/mashmap", mode: 'copy', pattern: "*.tsv"

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
