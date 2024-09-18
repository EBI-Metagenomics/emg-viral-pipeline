process fastqc {
    label 'fastqc'  
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

/* Comments:
*/