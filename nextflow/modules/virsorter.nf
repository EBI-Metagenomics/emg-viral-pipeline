process virsorter {
      publishDir "${params.output}/${name}/${params.virusdir}/", mode: 'copy', pattern: "*"
      label 'virsorter'

    input:
      tuple val(name), file(fasta), val(contig_number) 
      file(database) 

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("*")
    
    script:
      if (params.virome)
      """
      wrapper_phage_contigs_sorter_iPlant.pl -f ${fasta} --db 2 --wdir virsorter --ncpu ${task.cpus} --data-dir ${database} --virome
      """
      else
      """
      wrapper_phage_contigs_sorter_iPlant.pl -f ${fasta} --db 2 --wdir virsorter --ncpu ${task.cpus} --data-dir ${database}
      """
}

/*
  usage: wrapper_phage_contigs_sorter_iPlant.pl --fasta sequences.fa

  Required Arguments:

      -f|--fna       Fasta file of contigs

   Options:

      -d|--dataset   Code dataset (DEFAULT "VIRSorter")
      --cp           Custom phage sequence
      --db           Either "1" (DEFAULT Refseqdb) or "2" (Viromedb)
      --wdir         Working directory (DEFAULT cwd)
      --ncpu         Number of CPUs (default: 4)
      --virome       Add this flag to enable virome decontamination mode, for datasets
                     mostly viral to force the use of generic metrics instead of
                     calculated from the whole dataset. (default: off)
      --data-dir     Path to "virsorter-data" directory (e.g. /path/to/virsorter-data)
      --diamond      Use diamond (in "--more-sensitive" mode) instead of blastp.
                     Diamond is much faster than blastp and may be useful for adding
                     many custom phages, or for processing extremely large Fasta files.
                     Unless you specify --diamond, VirSorter will use blastp.
      --keep-db      Specifying this flag keeps the new HMM and BLAST databases created
                     after adding custom phages. This is useful if you have custom phages
                     that you want to be included in several different analyses and want
                     to save the database and point VirSorter to it in subsequent runs.
                     By default, this is off, and you should only specify this flag if
                     you're SURE you need it.
      --no_c         Use this option if you have issues with empty output files, i.e. 0
                     viruses predicted by VirSorter. This make VirSorter use a perl function
                     instead of the C script to calculate enrichment statistics. Note that
                     VirSorter will be slower with this option.
      --help         Show help and exit

*/