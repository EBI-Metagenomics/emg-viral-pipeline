/*
 * Filter contigs by length and rename.
*/
include { LENGTH_FILTERING } from '../../modules/local/length_filtering'
include { RENAME           } from '../../modules/local/rename'

workflow PREPROCESS {

    take:

    assembly

    main:

    // filter contigs by length
    LENGTH_FILTERING(assembly)  // out: (meta, filtered.fasta, env)

    filtered_fasta = LENGTH_FILTERING.out.map { meta, fasta, _contigs -> tuple(meta, fasta) }

    // rename the length-filtered assembly
    RENAME(filtered_fasta)  // out: (meta, renamed.fasta, map)

    emit:
    // tuple val(meta), file("${meta.id}_renamed.fasta"), file("${meta.id}_map.tsv"), file("${meta.id}_filtered.fasta"), env(CONTIGS)
    preprocessed_data = RENAME.out.join(LENGTH_FILTERING.out, by: 0)
}