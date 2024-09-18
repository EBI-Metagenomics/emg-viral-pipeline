/*
 * Rename all contigs and filter by length. 
*/

workflow PREPROCESS {

    take:
    
    assembly

    main:
  
    rename(assembly)

    // filter contigs by length
    length_filtering(rename.out)

    emit:
    rename.out.join(length_filtering.out, by: 0) //  tuple val(name), file("${name}_renamed.fasta"), file("${name}_map.tsv"), file("${name}*filt*.fasta"), env(CONTIGS)
}