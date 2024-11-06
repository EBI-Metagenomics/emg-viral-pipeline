process VIRSORTER2 {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/microbiome-informatics/virsorter:2.2.4'
    
    input:
      tuple val(meta), file(fasta), val(number_of_contigs) 
      path(database) 

    when: 
      number_of_contigs.toInteger() > 0 

    output:
      tuple val(meta), path("*.final-viral-score.tsv"),    emit: score_tsv
      tuple val(meta), path("*.final-viral-boundary.tsv"), emit: boundary_tsv
      tuple val(meta), path("*.final-viral-combined.fa"),  emit: combined_fa

    script:
      def args = task.ext.args ?: ''
      """
      # Settings to speed up hmmsearch
      # TODO: this needs to be tested, it doesn't seem to speed up so we decided to chunk the fasta instead
      #virsorter config --set HMMSEARCH_THREADS=4
      #virsorter config --set FAA_BP_PER_SPLIT=50000
      
      # extract chunk number to rename output files
      filename=\$(basename ${fasta})
      # Extract VALUE (assuming the filename is in format NAME.VALUE.fasta)
      export value="all"
      value=\$(echo "\$filename" | cut -d'.' -f2)
    
      virsorter run \
                --db-dir ${database} \
                -w virsorter2 \
                -i ${fasta} \
                -j ${task.cpus} \
                $args \
                all
      
      # Rename files
      mv virsorter2/final-viral-score.tsv "\${value}.final-viral-score.tsv"
      mv virsorter2/final-viral-boundary.tsv "\${value}.final-viral-boundary.tsv"
      mv virsorter2/final-viral-combined.fa "\${value}.final-viral-combined.fa"
      """
}