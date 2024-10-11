/*
 * Rename all contigs and filter by length. 
*/
include { LENGTH_FILTERING } from '../../modules/local/length_filtering'
include { RENAME           } from '../../modules/local/rename'

workflow PREPROCESS {

    take:
    
    assembly

    main:
  
    RENAME(assembly)       // out: (meta, renamed.fasta, map)

    // filter contigs by length
    LENGTH_FILTERING(RENAME.out)  // out: (meta, filt_fasta, env)

    emit:
    //  tuple val(meta), file("${meta.id}_renamed.fasta"), file("${meta.id}_map.tsv"), file("${meta.id}*filt*.fasta"), env(CONTIGS)
    preprocessed_data = RENAME.out.join(LENGTH_FILTERING.out, by: 0)
}