process virsorter2 {
      publishDir "${params.output}/${name}/${params.virusdir}/", mode: 'copy', pattern: "virsorter2/*"
      label 'virsorter2'

    input:
      tuple val(name), file(fasta), val(contig_number) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("virsorter2/*")
    
    script:
      """
      #virsorter config --init-source --db-dir=${params.databases}/virsorter2/virsorter2-data
      virsorter run -w virsorter2 -i ${fasta}  -j ${task.cpus} all
      """
}