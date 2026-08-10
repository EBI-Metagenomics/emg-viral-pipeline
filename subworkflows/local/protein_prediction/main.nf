include { PYRODIGAL       } from '../../../modules/nf-core/pyrodigal/main'
include { RENAME_PRODIGAL } from '../../../modules/local/rename_prodigal'

workflow PREDICT_PROTEINS {
    take:
    input_fastas // (meta, fasta)

    main:

        // ORF detection --> pyrodigal
        PYRODIGAL(
            input_fastas,
            "gff"
        )
        // That process was used for Prodigal process and left after we switched to pyrodigal
        // it renames ID in prodigal gff from digit_digit to protein name in prodigal header in faa file
        RENAME_PRODIGAL(
             PYRODIGAL.out.annotations.join(PYRODIGAL.out.faa)
        )

    emit:
        predicted_proteins = RENAME_PRODIGAL.out.gff.join(PYRODIGAL.out.faa)
}
