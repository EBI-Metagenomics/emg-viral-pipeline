include { PRODIGAL } from '../../modules/local/prodigal'

workflow PREDICT_PROTEINS {
    take:
    input_fastas

    main:

    proteins = channel.empty()

    if (params.use_proteins) {
        // skip prodigal step and use existing faa-s
        proteins = input_fastas.map { meta, type, _pred_contigs, faa, _contigs -> tuple(meta, type, faa) }
        contigs = input_fastas.map { meta, _type, _pred_contigs, _faa, contigs -> tuple(meta, contigs) }
        predicted_contigs = input_fastas.map { meta, type, pred_contigs, _faa, _contigs_ -> tuple(meta, type, pred_contigs) }
    }
    else {
        // ORF detection --> prodigal
        predicted_contigs = input_fastas.map { meta, type, pred_contigs, _contigs_ -> tuple(meta, type, pred_contigs) }
        contigs = input_fastas.map { meta, _type, _pred_contigs, contigs_ -> tuple(meta, contigs_) }
        PRODIGAL(predicted_contigs)
        proteins = PRODIGAL.out
    }

    emit:
    contigs           = contigs
    predicted_contigs = predicted_contigs
    proteins          = proteins
}
