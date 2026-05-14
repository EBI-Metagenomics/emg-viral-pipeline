include { PRODIGAL } from '../../modules/local/prodigal'

workflow PREDICT_PROTEINS {
    take:
    input_fastas // (meta, set_name, fasta) or (meta, set_name, fasta, faa, gff) when use_proteins

    main:

    proteins       = channel.empty()
    proteins_gff   = channel.empty()
    category_fasta = channel.empty()

    if (params.use_proteins) {
        category_fasta = input_fastas.map { meta, type, fasta, _faa, _gff -> tuple(meta, type, fasta) }
        proteins       = input_fastas.map { meta, type, _fasta, faa, _gff -> tuple(meta, type, faa) }
        proteins_gff   = input_fastas.map { meta, type, _fasta, _faa, gff -> tuple(meta, type, gff) }
    }
    else {
        category_fasta = input_fastas

        // ORF detection --> prodigal
        PRODIGAL(input_fastas)
        proteins     = PRODIGAL.out.proteins
        proteins_gff = PRODIGAL.out.gff
    }

    emit:
    category_fasta = category_fasta
    proteins       = proteins
    proteins_gff   = proteins_gff
}
