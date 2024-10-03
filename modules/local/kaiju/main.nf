process KAIJU {
    
    /*
    TODO: also get lists for the Classified reads!
    TODO: include viruses.taxids
    */

    label 'process_high'
    tag "${meta.id}"
    container 'quay.io/biocontainers/kaiju:1.7.2--hdbcaa40_0'
    
    input:
      tuple val(meta), path(fastq) 
      path(database) 
    
    output:
      tuple val(meta), path("${meta.id}.out")
      tuple val(meta), path("${meta.id}.out.krona")
    
    shell:
      if (params.illumina) {
      '''
      kaiju -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq[0]} -j !{fastq[1]} -o !{meta.id}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{meta.id}.out -o !{meta.id}.out.krona
      '''
      } 
      if (params.fasta) {
      '''
      kaiju -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq} -o !{meta.id}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{meta.id}.out -o !{meta.id}.out.krona
      '''
      }
}

