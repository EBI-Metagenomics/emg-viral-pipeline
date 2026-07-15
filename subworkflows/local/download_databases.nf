/**************************
* DATABASES
**************************/

/* 
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use.*/

include { checkVGetDB     } from '../../modules/local/get_db/checkv'
include { virfinderGetDB  } from '../../modules/local/get_db/virfinder'
include { pprmetaGet      } from '../../modules/local/get_db/pprmeta'
include { metaGetDB       } from '../../modules/local/get_db/meta'
include { virsorterGetDB  } from '../../modules/local/get_db/virsorter'
include { virsorter2GetDB } from '../../modules/local/get_db/virsorter2'
include { viphogGetDB     } from '../../modules/local/get_db/viphog'
include { ncbiGetDB       } from '../../modules/local/get_db/ncbi'
include { rvdbGetDB       } from '../../modules/local/get_db/rvdb'
include { pvogsGetDB      } from '../../modules/local/get_db/pvogs'
include { vogdbGetDB      } from '../../modules/local/get_db/vogdb'
include { vpfGetDB        } from '../../modules/local/get_db/vpf'
include { imgvrGetDB      } from '../../modules/local/get_db/imgvr'


// Builds the two channels needed to decide whether a database should be
// downloaded: `db_input` (the pre-supplied path, if any) and
// `ch_download_trigger` (fires exactly once when no path was supplied).
// This is a plain function - not a workflow - because a workflow/process
// can only be invoked once per enclosing workflow without include-aliasing,
// and this needs to run once per database.
def decisionMaker(db, db_link) {
    def db_input = db
        ? channel.of( [['id': 'db'], db] )
        : channel.empty()

    def ch_download_trigger = db_input
        .count()
        .filter { count -> count == 0 }
        .combine(channel.of(db_link))
        .map { count, link -> tuple(['id': 'db'], link) }

    return [db_input, ch_download_trigger]
}

workflow DOWNLOAD_DATABASES {
    take:
    pprmeta_db
    pprmeta_db_link
    virsorter_db
    virsorter_db_link
    virsorter2_db
    virsorter2_db_link
    virfinder_db
    virfinder_db_link
    viphog_db
    viphog_db_link
    ncbi_db
    ncbi_db_link
    checkv_db
    checkv_db_link
    rvdb_db
    rvdb_db_link
    pvogs_db
    pvogs_db_link
    vogdb_db
    vogdb_db_link
    vpf_db
    vpf_db_link
    imgvr_db
    imgvr_db_link
    meta_db
    meta_db_link

    main:
    // PPR-Meta
    def (pprmeta_input, pprmeta_trigger) = decisionMaker(pprmeta_db, pprmeta_db_link)
    pprmetaGet(pprmeta_trigger)
    pprmeta_downloaded_db = pprmeta_input.mix(pprmetaGet.out.database_dir).first()

    // VirSorter / VirSorter2
    if (params.use_virsorter_v1) {
        def (virsorter_input, virsorter_trigger) = decisionMaker(virsorter_db, virsorter_db_link)
        virsorterGetDB(virsorter_trigger)
        virsorter_downloaded_db = virsorter_input.mix(virsorterGetDB.out.database_dir).first()
    }
    else {
        def (virsorter2_input, virsorter2_trigger) = decisionMaker(virsorter2_db, virsorter2_db_link)
        virsorter2GetDB(virsorter2_trigger)
        virsorter_downloaded_db = virsorter2_input.mix(virsorter2GetDB.out.database_dir).first()
    }

    // VirFinder
    def (virfinder_input, virfinder_trigger) = decisionMaker(virfinder_db, virfinder_db_link)
    virfinderGetDB(virfinder_trigger)
    virfinder_downloaded_db = virfinder_input.mix(virfinderGetDB.out.database_dir).first()

    // ViPhOG
    def (viphog_input, viphog_trigger) = decisionMaker(viphog_db, viphog_db_link)
    viphogGetDB(viphog_trigger)
    viphog_downloaded_db = viphog_input.mix(viphogGetDB.out.database_dir).first()

    // NCBI taxonomy
    def (ncbi_input, ncbi_trigger) = decisionMaker(ncbi_db, ncbi_db_link)
    ncbiGetDB(ncbi_trigger)
    ncbi_downloaded_db = ncbi_input.mix(ncbiGetDB.out.database_dir).first()

    // CheckV
    def (checkv_input, checkv_trigger) = decisionMaker(checkv_db, checkv_db_link)
    checkVGetDB(checkv_trigger)
    checkv_downloaded_db = checkv_input.mix(checkVGetDB.out.database_dir).first()

    // Additional HMM databases, only needed with --hmmextend
    if (params.hmmextend) {
        def (rvdb_input, rvdb_trigger) = decisionMaker(rvdb_db, rvdb_db_link)
        rvdbGetDB(rvdb_trigger)
        rvdb_downloaded_db = rvdb_input.mix(rvdbGetDB.out.database_dir).first()

        def (pvogs_input, pvogs_trigger) = decisionMaker(pvogs_db, pvogs_db_link)
        pvogsGetDB(pvogs_trigger)
        pvogs_downloaded_db = pvogs_input.mix(pvogsGetDB.out.database_dir).first()

        def (vogdb_input, vogdb_trigger) = decisionMaker(vogdb_db, vogdb_db_link)
        vogdbGetDB(vogdb_trigger)
        vogdb_downloaded_db = vogdb_input.mix(vogdbGetDB.out.database_dir).first()

        def (vpf_input, vpf_trigger) = decisionMaker(vpf_db, vpf_db_link)
        vpfGetDB(vpf_trigger)
        vpf_downloaded_db = vpf_input.mix(vpfGetDB.out.database_dir).first()
    }
    else {
        rvdb_downloaded_db = channel.empty()
        pvogs_downloaded_db = channel.empty()
        vogdb_downloaded_db = channel.empty()
        vpf_downloaded_db = channel.empty()
    }

    // IMG/VR, only needed with --blastextend
    if (params.blastextend) {
        def (imgvr_input, imgvr_trigger) = decisionMaker(imgvr_db, imgvr_db_link)
        imgvrGetDB(imgvr_trigger)
        imgvr_downloaded_db = imgvr_input.mix(imgvrGetDB.out.database_dir).first()
    }
    else {
        imgvr_downloaded_db = channel.empty()
    }

    // ViPhOG metadata
    def (meta_input, meta_trigger) = decisionMaker(meta_db, meta_db_link)
    metaGetDB(meta_trigger)
    meta_downloaded_db = meta_input.mix(metaGetDB.out.database_dir).first()

    emit:
    pprmeta_downloaded_db
    virsorter_downloaded_db
    virfinder_downloaded_db
    viphog_downloaded_db
    ncbi_downloaded_db
    checkv_downloaded_db
    rvdb_downloaded_db
    pvogs_downloaded_db
    vogdb_downloaded_db
    vpf_downloaded_db
    imgvr_downloaded_db
    meta_downloaded_db
}
