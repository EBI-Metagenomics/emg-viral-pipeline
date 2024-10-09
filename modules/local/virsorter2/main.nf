process VIRSORTER2 {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/microbiome-informatics/virsorter:2'
    
    input:
      tuple val(meta), file(fasta), val(contig_number) 
      path(database) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("virsorter2/*.{tsv,fa*}")

    script:
      def args = task.ext.args ?: ''
      """
      # speed up hmmsearch
      virsorter config --set HMMSEARCH_THREADS=${task.cpus}
      
      virsorter run \
                --db-dir ${database} \
                -w virsorter2 \
                -i ${fasta} \
                -j ${task.cpus} \
                $args \
                all
      """
}