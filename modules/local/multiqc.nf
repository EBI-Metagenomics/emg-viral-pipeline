process multiqc {
    publishDir "${params.output}/${name}/${params.assemblydir}", mode: 'copy', pattern: "${name}_multiqc_report.html"
    label 'multiqc'  
  input:
    tuple val(name), file(fastqc)
  output:
    tuple val(name), file("${name}_multiqc_report.html")
  script:
    """
    multiqc -i ${name} .
    """
  }

/* Comments:
*/