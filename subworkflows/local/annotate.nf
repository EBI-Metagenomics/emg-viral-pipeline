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

include { VIRSORTER                   } from '../../modules/local/virsorter' 
include { VIRFINDER                   } from '../../modules/local/virfinder' 
include { PPRMETA                     } from '../../modules/local/pprmeta'
include { LENGTH_FILTERING            } from '../../modules/local/length_filtering'  
include { PRODIGAL                    } from '../../modules/local/prodigal'
include { HMMSCAN as HMMSCAN_VIPHOGS  } from '../../modules/local/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'viphogs', version: params.viphog_version)
include { HMMSCAN as HMMSCAN_RVDB     } from '../../modules/local/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'rvdb', version: params.viphog_version)
include { HMMSCAN as HMMSCAN_PVOGS    } from '../../modules/local/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'pvogs', version: params.viphog_version)
include { HMMSCAN as HMMSCAN_VOGDB    } from '../../modules/local/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vogdb', version: params.viphog_version)
include { HMMSCAN as HMMSCAN_VPF      } from '../../modules/local/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vpf', version: params.viphog_version)
include { HMM_POSTPROCESSING          } from '../../modules/local/hmm_postprocessing'
include { RATIO_EVALUE                } from '../../modules/local/ratio_evalue' 
include { ANNOTATION                  } from '../../modules/local/annotation' 
include { ASSIGN                      } from '../../modules/local/assign' 
include { BLAST                       } from '../../modules/local/blast' 
include { BLAST_FILTER                } from '../../modules/local/blast_filter'
include { MASHMAP                     } from '../../modules/local/mashmap'
include { CHECKV                      } from '../../modules/local/checkv'
include { WRITE_GFF                   } from '../../modules/local/write_gff'
include { PLOT_CONTIG_MAP             } from '../../modules/local/plot_contig_map'


workflow ANNOTATE {

    take:
    contigs
    predicted_contigs

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
    
    // ORF detection --> prodigal
    PRODIGAL( predicted_contigs )

    // Not implemented //
    //-- phanotate(predicted_contigs) --//

    // annotation --> hmmer
    HMMSCAN_VIPHOGS( PRODIGAL.out, viphog_db )
    HMM_POSTPROCESSING( HMMSCAN_VIPHOGS.out )

    // calculate hit qual per protein
    RATIO_EVALUE( HMM_POSTPROCESSING.out, additional_model_data )

    // annotate contigs based on ViPhOGs
    ANNOTATION( RATIO_EVALUE.out )

    // plot visuals --> PDFs
    PLOT_CONTIG_MAP( ANNOTATION.out )

    // assign lineages
    ASSIGN( ANNOTATION.out, ncbi_db, factor_file )

    // blast IMG/VR for more information
    if (params.blastextend) {
      BLAST( predicted_contigs, imgvr_db )
      BLAST_FILTER( BLAST.out, imgvr_db )
    }

    // hmmer additional databases
    if ( params.hmmextend ) {
      HMMSCAN_RVDB( PRODIGAL.out, rvdb_db )
      HMMSCAN_PVOGS( PRODIGAL.out, pvogs_db )
      HMMSCAN_VOGDB( PRODIGAL.out, vogdb_db )
      HMMSCAN_VPF( PRODIGAL.out, vpf_db )
    }

    if ( params.mashmap ) {
        MASHMAP( predicted_contigs, mashmap_ref_ch )
    }

    CHECKV(
      predicted_contigs.combine( contigs.map { name, fasta -> fasta }),
      checkv_db
    )

    viphos_annotations = ANNOTATION.out.map { _, __, annotations -> annotations }.collect()
    taxonomy_annotations = ASSIGN.out.map { _, __, taxonomy -> taxonomy }.collect()
    checkv_results = CHECKV.out.map { _, __, quality_summary, ___ -> quality_summary }.collect()

    WRITE_GFF(
      contigs.first(),
      viphos_annotations,
      taxonomy_annotations,
      checkv_results
    )

    predicted_contigs_filtered = predicted_contigs.map { id, set_name, fasta -> [set_name, id, fasta] }
    plot_contig_map_filtered = PLOT_CONTIG_MAP.out.map { id, set_name, dir, table -> [set_name, table] }
    chromomap_ch = predicted_contigs_filtered.join(plot_contig_map_filtered).map { set_name, assembly_name, fasta, tsv -> [assembly_name, set_name, fasta, tsv]}

    emit:
    assign_output = ASSIGN.out
    chromomap = chromomap_ch
}
