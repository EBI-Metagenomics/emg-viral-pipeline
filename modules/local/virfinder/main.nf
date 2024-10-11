process VIRFINDER {
    tag "${meta.id}"  
    label 'process_medium'
      
    container 'quay.io/microbiome-informatics/virfinder:1.1__eb8032e'
    
    input:
      tuple val(meta), path(fasta), val(contig_number)
      path model
    
    when: 
      contig_number.toInteger() > 0 
    
    output:
      tuple val(meta), path("${meta.id}.txt")
    
    script:
      """
      run_virfinder.Rscript ${model} ${fasta} .
      awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$4}' ${meta.id}*.tsv > ${meta.id}.txt
      """
}
