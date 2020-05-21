process mashmap {
      label 'mashmap'

      publishDir "${params.output}/${assembly_name}/", mode: 'copy', pattern: "*.tsv"
      publishDir "${params.output}/${assembly_name}/${params.finaldir}/mashmap", mode: 'copy', pattern: "*.tsv"

    input:
      tuple val(assembly_name), val(confidence_set_name), file(fasta) 
      file(reference)
      val(length) 
    
    output:
      file("${confidence_set_name}_mashmap_hits.tsv")
    
    shell:
    """
    mashmap -q ${fasta} -r ${reference} -t ${params.cores} -o ${confidence_set_name}_mashmap_hits.tsv --noSplit -s ${length}
    """
}