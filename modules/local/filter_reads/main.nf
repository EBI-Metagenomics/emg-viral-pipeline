process FILTER_READS {

    label 'process_low'

    input:
      tuple val(name), file(kaiju_filtered), file(fastq) 
    
    output:
      tuple val(name), file("${name}.filtered.fastq")
      tuple val(name), file("${name}.filtered.fasta")
    
    script:
    """
    sed '/^@/!d;s//>/;N' ${fastq} > ${name}.fasta
    faSomeRecords ${name}.fasta ${kaiju_filtered} ${name}.filtered.fasta
    faToFastq ${name}.filtered.fasta ${name}.filtered.fastq
    rm -f ${name}.fasta
    """
}
