process virsorter2 {
      publishDir "${params.output}/${name}/${params.virusdir}/", mode: 'copy', pattern: "virsorter2/*.{tsv,fasta}"
      label 'virsorter2'

    input:
      tuple val(name), file(fasta), val(contig_number) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("virsorter2/*.{tsv,fa}")
    
    script:
      """
      virsorter run -w virsorter2 -i ${fasta}  -j ${task.cpus} all
      """
}