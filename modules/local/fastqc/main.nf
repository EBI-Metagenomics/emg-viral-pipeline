process FASTQC {
  tag "${name}"
  label 'process_low'  
  container 'quay.io/biocontainers/fastqc:0.11.9--hdfd78af_1'
  
  input:
    tuple val(name), file(reads)
  output:
    tuple val(name), file("fastqc/${name}*fastqc*")
  script:
    """
    mkdir fastqc
    fastqc -t ${task.cpus} -o fastqc *.fastq.gz
    """
}