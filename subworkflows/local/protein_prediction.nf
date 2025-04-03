
include { PRODIGAL                    } from '../../modules/local/prodigal'


workflow PREDICT_PROTEINS {

    take:
    input_fastas
    
    main:
    
    proteins = Channel.empty()
    if (params.use_proteins) {
      // skip prodigal step and use existing faa-s
      proteins = input_fastas.map{meta, type, pred_contigs, faa, contigs -> tuple(meta, type, faa)}
      contigs = input_fastas.map{meta, type, pred_contigs, faa, contigs -> tuple(meta, contigs)}
      predicted_contigs = input_fastas.map{meta, type, pred_contigs, faa, contigs -> tuple(meta, type, pred_contigs)}
    } else {
      // ORF detection --> prodigal
      predicted_contigs = input_fastas.map{meta, type, pred_contigs, contigs -> tuple(meta, type, pred_contigs)}
      PRODIGAL( predicted_contigs )
      proteins = PRODIGAL.out
      contigs = input_fastas.map{meta, type, pred_contigs, contigs -> tuple(meta, contigs)}
    }
    
    emit:
    contigs           = contigs
    predicted_contigs = predicted_contigs
    proteins          = proteins
}