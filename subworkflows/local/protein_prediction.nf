include { PRODIGAL        } from '../../modules/local/prodigal'
include { RENAME_PRODIGAL } from '../../modules/local/rename_prodigal'

workflow PREDICT_PROTEINS {
    take:
    input_fastas // (meta, fasta) 

    main:
    
        // ORF detection --> prodigal
        PRODIGAL(
            input_fastas
        )
        
        RENAME_PRODIGAL(
             PRODIGAL.out.proteins_files
        )
        proteins_gff = RENAME_PRODIGAL.out.gff

    emit:
        predicted_proteins = PRODIGAL.out.proteins_files.join(proteins_gff).map{ meta, gff, faa, renamed_gff -> [meta, renamed_gff, faa]}
}
