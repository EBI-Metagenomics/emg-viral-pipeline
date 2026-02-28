include { PRODIGAL } from '../../modules/local/prodigal'

workflow PREDICT_PROTEINS {
    take:
    input_fastas // (meta, set_name, fasta) or (meta, set_name, fasta, faa) when use_proteins

    main:

    proteins       = channel.empty()
    category_fasta = channel.empty()

    if (params.use_proteins) {
        category_fasta = input_fastas.map { meta, type, fasta, _faa -> tuple(meta, type, fasta) }

        // skip prodigal step and use existing faa-s
        proteins = input_fastas.map { meta, type, _fasta, faa -> tuple(meta, type, faa) }
    }
    else {
        category_fasta = input_fastas

        // ORF detection --> prodigal
        PRODIGAL(input_fastas)
        proteins = PRODIGAL.out
    }

    emit:
    category_fasta = category_fasta
    proteins       = proteins
}
