process KAIJU {
    
    /*
    TODO: also get lists for the Classified reads!
    TODO: include viruses.taxids
    */

    label 'process_medium'
    
    container 'quay.io/biocontainers/kaiju:1.7.2--hdbcaa40_0'
    
    input:
      tuple val(name), file(fastq) 
      file(database) 
    
    output:
      tuple val(name), file("${name}.out")
      tuple val(name), file("${name}.out.krona")
    
    shell:
      if (params.illumina) {
      '''
      kaiju -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq[0]} -j !{fastq[1]} -o !{name}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{name}.out -o !{name}.out.krona
      '''
      } 
      if (params.fasta) {
      '''
      kaiju -z !{task.cpus} -t !{database}/nodes.dmp -f !{database}/!{database}/kaiju_db_!{database}.fmi -i !{fastq} -o !{name}.out
      kaiju2krona -t !{database}/nodes.dmp -n !{database}/names.dmp -i !{name}.out -o !{name}.out.krona
      '''
      }
}

