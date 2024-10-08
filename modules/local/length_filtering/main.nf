process LENGTH_FILTERING {
    label 'process_single'
    tag "${meta.id}"
    container 'quay.io/biocontainers/biopython:1.75'

    input:
      tuple val(meta), path(fasta), path(map) 
    
    output:
      tuple val(meta), path("${meta.id}*filt*.fasta"), env(CONTIGS)
    
    script:
    """    
      filter_contigs_len.py -f ${fasta} -l ${params.length} -o ./
      CONTIGS=\$(grep ">" ${meta.id}*filt*.fasta | wc -l)
    """
}

/*
  usage: filter_contigs_len.py [-h] -f input_file -l length_thres -o output_dir -i sample_id

  Extract sequences at least X kb long.

  positional arguments:
    fasta              Path to fasta file to filter

  optional arguments:
    -h, --help         show this help message and exit
    -l LENGTH          Length threshold in kb of selected sequences (default: 5kb)
    -o OUTDIR          Relative or absolute path to directory where you want to store output (default: cwd)
    -i IDENT           Dataset identifier or accession number. Should only be introduced if you want to add it to each sequence header, along with a sequential number
*/
