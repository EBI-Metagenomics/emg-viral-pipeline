/* Comment section:
Restore original contig names. 
*/

include { RESTORE } from '../../modules/local/restore'

workflow POSTPROCESS {
    take:   fasta
    main:
        // restore contig names
        RESTORE(fasta)
    emit:
        restored_fasta = RESTORE.out
}