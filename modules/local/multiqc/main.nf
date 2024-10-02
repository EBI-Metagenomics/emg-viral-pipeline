process MULTIQC {
    label 'process_low'  
    tag "${name}"
    container 'quay.io/biocontainers/multiqc:1.9--py_1'
    
    input:
      tuple val(name), file(fastqc)
    output:
      tuple val(name), file("${name}_multiqc_report.html")
      
    script:
    """
    multiqc -i ${name} .
    """
}
