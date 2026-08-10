include { CHECK_PROTEINS_COMPATIBILITY      } from '../../../modules/local/check_proteins_compatibility'
include { RENAME_PRODIGAL                   } from '../../../modules/local/rename_prodigal'


workflow PROTEINS_COMPATIBILITY {
    take:
    records_with_proteins // [meta, fna, gff, faa]

    main:
    // check proteins compatibility with pipeline expectations
    CHECK_PROTEINS_COMPATIBILITY(
        records_with_proteins
    )

    // reduce the "results/<status>" glob output to a single status name per sample
    compatibility_status = CHECK_PROTEINS_COMPATIBILITY.out.status
        .map { meta, results ->
            def resultsList = results instanceof List ? results : [results]
            tuple(meta, resultsList[0].name)
        }
    // Check whether a user-supplied fasta/faa/gff triplet is
    // internally consistent (marked matched or not_matched)
    // and whether the faa/gff still use prodigal's short-format protein IDs and therefore need renaming (marked require_rename)
    checked_records = records_with_proteins
        .join(compatibility_status)
        .branch { meta, fasta, proteins_gff, proteins_faa, status ->
            not_matched: status == 'not_matched'
                return tuple(meta, fasta, proteins_gff, proteins_faa)
            require_rename: status == 'require_rename'
                return tuple(meta, fasta, proteins_gff, proteins_faa)
            matched: status == 'matched'
                return tuple(meta, fasta, proteins_gff, proteins_faa)
        }

    // ----------- report and drop samples whose supplied proteins don't match their assembly
    not_matched_proteins_report = checked_records.not_matched
        .map { meta, _fasta, _proteins_gff, _proteins_faa ->
            "${meta.id}\tproteins_faa/proteins_gff do not match the provided assembly; sample excluded from the pipeline\n"
        }
        .collectFile(
            name: "not_matched_proteins_report.tsv",
            storeDir: "${params.output}",
            seed: "id\treason\n",
            sort: true
        )

    // ----------- rename prodigal's short-format protein IDs to the long contig-based format
    RENAME_PRODIGAL(
        checked_records.require_rename.map { meta, _fasta, proteins_gff, proteins_faa -> tuple(meta, proteins_gff, proteins_faa) }
    )
    renamed_records = checked_records.require_rename
        .map { meta, fasta, _proteins_gff, proteins_faa -> tuple(meta, fasta, proteins_faa) }
        .join(RENAME_PRODIGAL.out.gff)
        .map { meta, fasta, proteins_faa, renamed_gff -> tuple(meta, fasta, renamed_gff, proteins_faa) }

    emit:
    matched_records = checked_records.matched
    renamed_records = renamed_records
    not_matched_proteins_report = not_matched_proteins_report
}
