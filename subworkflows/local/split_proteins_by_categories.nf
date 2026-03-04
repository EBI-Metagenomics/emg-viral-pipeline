include { SPLIT_PROTEINS } from '../../modules/local/split_proteins'

workflow SPLIT_PROTEINS_BY_CATEGORIES {
    /* 
     * Cut proteins fasta into HC, LC and PP detections 
    */

    take:
    input

    main:
    SPLIT_PROTEINS(input)

    emit:
    splitted_proteins = SPLIT_PROTEINS.out
}
