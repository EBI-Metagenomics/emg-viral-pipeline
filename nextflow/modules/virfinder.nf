process virfinder {
      errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
      publishDir "${params.output}/${name}/${params.virusdir}/virfinder", mode: 'copy', pattern: "${name}.txt"
      label 'virfinder'
    
    input:
      tuple val(name), file(fasta), val(contig_number)
    
    when: 
      contig_number.toInteger() > 0 
    
    output:
      tuple val(name), file("${name}.txt")
    
    script:
      """
      #Rscript /usr/local/bin/run_virfinder.Rscript ${fasta} ${name}.txt
      
      #run_virfinder_non_parallel.Rscript ${fasta} ${name}.txt

      wget https://github.com/jessieren/VirFinder/raw/master/EPV/VF.modEPV_k8.rda
      run_virfinder_modEPV.Rscript VF.modEPV_k8.rda ${fasta} .
      awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$4}' ${name}*.txt > ${name}.txt
      """
}