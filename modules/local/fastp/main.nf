process FASTP {

/* Comments:
  -m, --merge   
  for paired-end input, merge each pair of reads into a single read if they are overlapped. 
  The merged reads will be written to the file given by --merged_out, the unmerged reads will be 
  written to the files specified by --out1 and --out2. The merging mode is disabled by default.
*/
  tag "${name}"
  label 'process_medium'  
  container 'quay.io/biocontainers/fastp:0.20.1--h8b12597_0'
  
  input:
    tuple val(name), file(reads)
  output:
    tuple val(name), file("${name}*.fastp.fastq.gz")
  script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} --thread ${task.cpus} -o ${name}.R1.fastp.fastq.gz -O ${name}.R2.fastp.fastq.gz
    """
}