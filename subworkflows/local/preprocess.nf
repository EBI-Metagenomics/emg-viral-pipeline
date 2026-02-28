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

    filtered_fasta = LENGTH_FILTERING.out.map { meta, fasta, contigs_count -> tuple(meta, fasta, contigs_count) }

    // rename the length-filtered assembly
    RENAME(filtered_fasta)  // out: (meta, renamed.fasta, map)

    emit:
    mapfile                            = RENAME.out.mapfile
    filtered_and_renamed_contigs_fasta = RENAME.out.renamed_fasta
}
