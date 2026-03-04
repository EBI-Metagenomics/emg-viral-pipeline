/*
 * Predict ORFs and align HMMs to taxonomically annotate each contig.
 * Apply bit score cutoffs and filters to distinguish informative ViPhOG HMMs
 * and finally taxonomically annotate contigs, if possible.
 *
 * Also runs additional HMM from further databases if defined and can also run a simple BLAST
 * approach based on IMG/VR. Finally, mashmap can be used for the particular detection of a specific reference virus sequence.
 *
 * Then, all results are summarized for reporting and plotting.
 */

/* nf-core modules */
include { TABIX_BGZIP                 } from '../../modules/nf-core/tabix/bgzip/main'
include { TABIX_BGZIPTABIX            } from '../../modules/nf-core/tabix/bgziptabix/main'

/* Local modules */
include { RATIO_EVALUE                } from '../../modules/local/ratio_evalue'
include { ANNOTATION                  } from '../../modules/local/annotation'
include { ASSIGN                      } from '../../modules/local/assign'
include { BLAST                       } from '../../modules/local/blast'
include { BLAST_FILTER                } from '../../modules/local/blast_filter'
include { MASHMAP                     } from '../../modules/local/mashmap'
include { CHECKV                      } from '../../modules/local/checkv'
include { WRITE_GFF                   } from '../../modules/local/write_gff'
include { PLOT_CONTIG_MAP             } from '../../modules/local/plot_contig_map'

include { HMMER_PREDICTION            } from './hmmer_processing'
include { PREDICT_PROTEINS            } from './protein_prediction'


workflow ANNOTATE {

    take:
    category_fastas     // (meta, set_name, fasta) or (meta, set_name, fasta, faa) when use_proteins
    assembly_fasta      // (meta, fasta) — full assembly per sample, used only for GFF output

    // reference databases and aux files //
    viphog_db
    ncbi_db
    rvdb_db
    pvogs_db
    vogdb_db
    vpf_db
    imgvr_db
    additional_model_data
    checkv_db
    factor_file
    mashmap_ref_ch

    main:

    // Extract per-category fasta and proteins (runs prodigal if not use_proteins)
    PREDICT_PROTEINS( category_fastas )

    category_fasta = PREDICT_PROTEINS.out.category_fasta
    proteins       = PREDICT_PROTEINS.out.proteins

    // annotation --> hmmer with chunking
    HMMER_PREDICTION(proteins, viphog_db, rvdb_db, pvogs_db, vogdb_db, vpf_db) // out: [meta, set_name, hmm_modified.tsv]

    // calculate hit qual per protein
    RATIO_EVALUE( HMMER_PREDICTION.out.hmm_result, additional_model_data )

    // annotate contigs based on ViPhOGs
    ANNOTATION( RATIO_EVALUE.out.join(proteins, by:[0,1]) )

    // plot visuals --> PDFs
    PLOT_CONTIG_MAP( ANNOTATION.out.annotations )

    // assign lineages
    ASSIGN( ANNOTATION.out.annotations, ncbi_db, factor_file )

    // blast IMG/VR for more information
    if (params.blastextend) {
      BLAST( category_fasta, imgvr_db )
      BLAST_FILTER( BLAST.out, imgvr_db )
    }

    if ( params.mashmap ) {
        MASHMAP( category_fasta, mashmap_ref_ch )
    }

    CHECKV(
      category_fasta,
      checkv_db.first()
    )

    // Collapse per-category results to per-sample lists for GFF writing
    viphos_annotations   = ANNOTATION.out.annotations.map { meta, _type, data -> [meta, data] }.groupTuple()
    taxonomy_annotations = ASSIGN.out.map { meta, _type, data -> [meta, data] }.groupTuple()
    checkv_results       = CHECKV.out.map { meta, _type, data -> [meta, data] }.groupTuple()

    WRITE_GFF(
      assembly_fasta
        .join(viphos_annotations)
        .join(taxonomy_annotations)
        .join(checkv_results)
    )

    /**********************************************/
    /* Compressed and indexed GFF (.gzi and .csi) */
    /**********************************************/
    TABIX_BGZIP(
      WRITE_GFF.out.gff
    )

    TABIX_BGZIPTABIX(
      WRITE_GFF.out.gff
    )

    chromomap_ch = category_fasta
        .join(PLOT_CONTIG_MAP.out, by: [0, 1])
        .map { meta, set_name, fasta, _dir, table -> [meta, set_name, fasta, table] }

    emit:
    assign_output = ASSIGN.out
    chromomap = chromomap_ch
}
