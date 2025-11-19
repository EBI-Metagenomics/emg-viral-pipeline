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
include { VIRSORTER                   } from '../../modules/local/virsorter' 
include { VIRFINDER                   } from '../../modules/local/virfinder' 
include { PPRMETA                     } from '../../modules/local/pprmeta'
include { LENGTH_FILTERING            } from '../../modules/local/length_filtering'  
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
    input_fastas  // (meta, type(HC/LC/PP), predicted_contigs, faa[optional], contigs)

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
    
    // prodigal
    PREDICT_PROTEINS( input_fastas )
    contigs = PREDICT_PROTEINS.out.contigs
    proteins = PREDICT_PROTEINS.out.proteins
    predicted_contigs = PREDICT_PROTEINS.out.predicted_contigs
    
    // annotation --> hmmer with chunking 
    HMMER_PREDICTION(proteins, viphog_db, rvdb_db, pvogs_db, vogdb_db, vpf_db) // out: [meta, type, hmm_modified.tsv]
    
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
      BLAST( predicted_contigs, imgvr_db )
      BLAST_FILTER( BLAST.out, imgvr_db )
    }

    if ( params.mashmap ) {
        MASHMAP( predicted_contigs, mashmap_ref_ch )
    }

    CHECKV(
      predicted_contigs,
      checkv_db.first()
    )
    
    viphos_annotations = ANNOTATION.out.annotations.map{meta, type, annotation -> [meta, annotation]}.groupTuple()
    taxonomy_annotations = ASSIGN.out.map{meta, type, annotation -> [meta, annotation]}.groupTuple()
    checkv_results = CHECKV.out.map{meta, type, quality -> [meta, quality]}.groupTuple()
    
    WRITE_GFF(
      contigs.join(viphos_annotations).join(taxonomy_annotations).join(checkv_results)
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

    predicted_contigs_filtered = predicted_contigs.map { meta, set_name, fasta -> [set_name, meta, fasta] }
    plot_contig_map_filtered = PLOT_CONTIG_MAP.out.map { meta, set_name, dir, table -> [set_name, table] }
    chromomap_ch = predicted_contigs_filtered.join(plot_contig_map_filtered).map { set_name, assembly_name, fasta, tsv -> [assembly_name, set_name, fasta, tsv]}
    
    emit:
    assign_output = ASSIGN.out
    chromomap = chromomap_ch
}
