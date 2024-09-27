process VIRFINDER {
      
    label 'process_high'
      
    container 'quay.io/microbiome-informatics/virfinder:1.1__eb8032e'
    
    input:
      tuple val(name), file(fasta), val(contig_number)
      path model
    
    when: 
      contig_number.toInteger() > 0 
    
    output:
      tuple val(name), file("${name}.txt")
    
    script:
      """
      run_virfinder.Rscript ${model} ${fasta} .
      awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$4}' ${name}*.tsv > ${name}.txt
      """
}
