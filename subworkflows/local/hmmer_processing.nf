
include { SEQKIT_SPLIT2                       } from '../../modules/nf-core/seqkit/split2/main'
include { CAT_CAT as CONCATENATE_HMMER_TBLOUT } from '../../modules/nf-core/cat/cat/main'

include { HMMER as HMMER_VIPHOGS              } from '../../modules/local/hmmer' 
include { HMMER as HMMER_RVDB                 } from '../../modules/local/hmmer'
include { HMMER as HMMER_PVOGS                } from '../../modules/local/hmmer' 
include { HMMER as HMMER_VOGDB                } from '../../modules/local/hmmer' 
include { HMMER as HMMER_VPF                  } from '../../modules/local/hmmer' 
include { HMM_POSTPROCESSING                  } from '../../modules/local/hmm_postprocessing'


workflow HMMER_PREDICTION {

    take:
    proteins
    viphog_db
    rvdb_db
    pvogs_db
    vogdb_db
    vpf_db
    
    main:
    
    // chunk big fasta file
    SEQKIT_SPLIT2(
        proteins,
        params.proteins_chunksize,
    )
    def ch_protein_chunks = SEQKIT_SPLIT2.out.assembly.transpose()

    HMMER_VIPHOGS( ch_protein_chunks, viphog_db )
    
    CONCATENATE_HMMER_TBLOUT(
        HMMER_VIPHOGS.out.groupTuple(by: [0,1])
    )
    
    HMM_POSTPROCESSING( CONCATENATE_HMMER_TBLOUT.out.file_out )

    // hmmer additional databases
    if ( params.hmmextend ) {
      HMMER_RVDB( proteins, rvdb_db )
      HMMER_PVOGS( proteins, pvogs_db )
      HMMER_VOGDB( proteins, vogdb_db )
      HMMER_VPF( proteins, vpf_db )
    }
    
    emit:
    hmm_result = HMM_POSTPROCESSING.out
}