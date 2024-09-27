/*
 * Rename all contigs and filter by length. 
*/
include { LENGTH_FILTERING } from '../../modules/local/length_filtering'
include { RENAME           } from '../../modules/local/rename'

workflow PREPROCESS {

    take:
    
    assembly

    main:
  
    RENAME(assembly)

    // filter contigs by length
    LENGTH_FILTERING(RENAME.out)

    emit:
    //  tuple val(name), file("${name}_renamed.fasta"), file("${name}_map.tsv"), file("${name}*filt*.fasta"), env(CONTIGS)
    preprocessed_data = RENAME.out.join(LENGTH_FILTERING.out, by: 0)
}