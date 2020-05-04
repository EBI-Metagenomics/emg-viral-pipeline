process filter_reads {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}.filtered.fastq"
      label 'ucsc'

    input:
      tuple val(name), file(kaiju_filtered), file(fastq) 
    
    output:
      tuple val(name), file("${name}.filtered.fastq")
      tuple val(name), file("${name}.filtered.fasta")
    
    shell:
    """
    sed '/^@/!d;s//>/;N' ${fastq} > ${name}.fasta
    faSomeRecords ${name}.fasta ${kaiju_filtered} ${name}.filtered.fasta
    faToFastq ${name}.filtered.fasta ${name}.filtered.fastq
    rm -f ${name}.fasta
    """
}
