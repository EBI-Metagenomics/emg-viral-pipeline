process VIRSORTER2 {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/microbiome-informatics/virsorter:2.2.4'
    
    input:
      tuple val(meta), file(fasta), val(contig_number) 
      path(database) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(meta), path("virsorter2/final-viral-score.tsv"),    emit: score_tsv
      tuple val(meta), path("virsorter2/final-viral-boundary.tsv"), emit: boundary_tsv
      tuple val(meta), path("virsorter2/final-viral-combined.fa"),  emit: combined_fa

    script:
      def args = task.ext.args ?: ''
      """
      # speed up hmmsearch
      #virsorter config --set HMMSEARCH_THREADS=4
      #virsorter config --set FAA_BP_PER_SPLIT=50000
      
      virsorter run \
                --db-dir ${database} \
                -w virsorter2 \
                -i ${fasta} \
                -j ${task.cpus} \
                $args \
                all
      """
}