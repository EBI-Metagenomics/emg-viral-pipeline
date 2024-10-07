/************************** 
* DATABASES
**************************/

/* Comment section:
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use.*/

include { checkVGetDB    } from '../../modules/local/get_db/checkv'
include { virfinderGetDB } from '../../modules/local/get_db/virfinder'
include { pprmetaGet     } from '../../modules/local/pprmeta'
include { metaGetDB      } from '../../modules/local/get_db/meta'
include { virsorterGetDB } from '../../modules/local/get_db/virsorter'
include { viphogGetDB    } from '../../modules/local/get_db/viphog'
include { ncbiGetDB      } from '../../modules/local/get_db/ncbi'
include { rvdbGetDB      } from '../../modules/local/get_db/rvdb'
include { pvogsGetDB     } from '../../modules/local/get_db/pvogs'
include { vogdbGetDB     } from '../../modules/local/get_db/vogdb'
include { vpfGetDB       } from '../../modules/local/get_db/vpf'
include { imgvrGetDB     } from '../../modules/local/get_db/imgvr'
include { kaijuGetDB     } from '../../modules/local/get_db/kaiju'

workflow download_pprmeta {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { pprmetaGet(); git = pprmetaGet.out }
    // cloud storage via preload.exists()
    if (params.cloudProcess) {
      preload = file("${params.databases}/pprmeta")
      if (preload.exists()) { git = preload }
      else  { pprmetaGet(); git = pprmetaGet.out } 
    }
  emit: git
}

workflow download_model_meta {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { metaGetDB(); db = metaGetDB.out }
    // cloud storage via preload.exists()
    if (params.cloudProcess) {
      preload = file("${params.databases}/models/additional_data_vpHMMs_${params.meta_version}.tsv")
      if (preload.exists()) { db = preload }
      else  { metaGetDB(); db = metaGetDB.out } 
    }
  emit: db
}

workflow download_virsorter_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { virsorterGetDB(); db = virsorterGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/virsorter/virsorter-data")
      if (db_preload.exists()) { db = db_preload }
      else  { virsorterGetDB(); db = virsorterGetDB.out } 
    }
  emit: db    
}

workflow download_virfinder_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { virfinderGetDB(); db = virfinderGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/virfinder/VF.modEPV_k8.rda")
      if (db_preload.exists()) { db = db_preload }
      else  { virfinderGetDB(); db = virfinderGetDB.out } 
    }
  emit: db
}

workflow download_viphog_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { viphogGetDB(); db = viphogGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/vpHMM_database_${params.viphog_version}")
      if (db_preload.exists()) { db = db_preload }
      else  { viphogGetDB(); db = viphogGetDB.out } 
    }
  emit: db    
}

workflow download_ncbi_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { ncbiGetDB(); db = ncbiGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/ncbi/ete3_ncbi_tax.sqlite")
      if (db_preload.exists()) { db = db_preload }
      else  { ncbiGetDB(); db = ncbiGetDB.out } 
    }
  emit: db
}

workflow download_rvdb_db {
    main:
    if (params.hmmextend) {
      // local storage via storeDir
      if (!params.cloudProcess) { rvdbGetDB(); db = rvdbGetDB.out }
      // cloud storage via db_preload.exists()
      if (params.cloudProcess) {
        db_preload = file("${params.databases}/rvdb")
        if (db_preload.exists()) { db = db_preload }
        else  { rvdbGetDB(); db = rvdbGetDB.out } 
      }
    } else {
      db = Channel.empty()
    }
  emit: db
}

workflow download_pvogs_db {
    main:
    if (params.hmmextend) {
      // local storage via storeDir
      if (!params.cloudProcess) { pvogsGetDB(); db = pvogsGetDB.out }
      // cloud storage via db_preload.exists()
      if (params.cloudProcess) {
        db_preload = file("${params.databases}/pvogs")
        if (db_preload.exists()) { db = db_preload }
        else  { pvogsGetDB(); db = pvogsGetDB.out } 
      }
    } else {
      db = Channel.empty()
    }
  emit: db
}

workflow download_vogdb_db {
    main:
    if (params.hmmextend) {
      // local storage via storeDir
      if (!params.cloudProcess) { vogdbGetDB(); db = vogdbGetDB.out }
      // cloud storage via db_preload.exists()
      if (params.cloudProcess) {
        db_preload = file("${params.databases}/vogdb")
        if (db_preload.exists()) { db = db_preload }
        else  { vogdbGetDB(); db = vogdbGetDB.out } 
      }
    } else {
      db = Channel.empty()
    }
  emit: db
}

workflow download_vpf_db {
    main:
    if (params.hmmextend) {
      // local storage via storeDir
      if (!params.cloudProcess) { vpfGetDB(); db = vpfGetDB.out }
      // cloud storage via db_preload.exists()
      if (params.cloudProcess) {
        db_preload = file("${params.databases}/vpf")
        if (db_preload.exists()) { db = db_preload }
        else  { vpfGetDB(); db = vpfGetDB.out } 
      }
    } else {
      db = Channel.empty()
    }
  emit: db
}

workflow download_imgvr_db {
    main:
    if (params.blastextend) {
      // local storage via storeDir
      if (!params.cloudProcess) { imgvrGetDB(); db = imgvrGetDB.out }
      // cloud storage via db_preload.exists()
      if (params.cloudProcess) {
        db_preload = file("${params.databases}/imgvr/IMG_VR_2018-07-01_4")
        if (db_preload.exists()) { db = db_preload }
        else  { imgvrGetDB(); db = imgvrGetDB.out } 
      }
    } else {
      db = Channel.empty()
    }
  emit: db
}

workflow download_checkv_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { checkVGetDB(); db = checkVGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/checkv", type: 'dir')
      if (db_preload.exists()) { db = db_preload }
      else  { checkVGetDB(); db = checkVGetDB.out } 
    }
  emit: db
}

/*
workflow download_kaiju_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { kaijuGetDB(); db = kaijuGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/kaiju/nr_euk")
      if (db_preload.exists()) { db = db_preload }
      else  { kaijuGetDB(); db = kaijuGetDB.out } 
    }
  emit: db    
}
*/

workflow DOWNLOAD_DATABASES {
   main:
   
    if (params.pprmeta) { pprmeta_git = file(params.pprmeta) }
    else { pprmeta_git = download_pprmeta() }
    
    if (params.virsorter) { virsorter_db = file(params.virsorter)} 
    else { download_virsorter_db(); virsorter_db = download_virsorter_db.out }
  
    if (params.virfinder) { virfinder_db = file(params.virfinder)} 
    else { download_virfinder_db(); virfinder_db = download_virfinder_db.out }
  
    if (params.meta) { additional_model_data = file(params.meta) }
    else { additional_model_data = download_model_meta() }
  
    if (params.viphog) { viphog_db = file(params.viphog)} 
    else {download_viphog_db(); viphog_db = download_viphog_db.out }
  
    if (params.rvdb) { rvdb_db = file(params.rvdb)} 
    else {download_rvdb_db(); rvdb_db = download_rvdb_db.out }
  
    if (params.pvogs) { pvogs_db = file(params.pvogs)} 
    else {download_pvogs_db(); pvogs_db = download_pvogs_db.out }
  
    if (params.vogdb) { vogdb_db = file(params.vogdb)} 
    else {download_vogdb_db(); vogdb_db = download_vogdb_db.out }
  
    if (params.vpf) { vpf_db = file(params.vpf)} 
    else {download_vpf_db(); vpf_db = download_vpf_db.out }
  
    if (params.ncbi) { ncbi_db = file(params.ncbi)} 
    else {download_ncbi_db(); ncbi_db = download_ncbi_db.out }
  
    if (params.imgvr) { imgvr_db = file(params.imgvr)} 
    else {download_imgvr_db(); imgvr_db = download_imgvr_db.out }
  
    if (params.checkv) { checkv_db = file(params.checkv)} 
    else {download_checkv_db(); checkv_db = download_checkv_db.out }
    
    emit:
    pprmeta_git
    virsorter_db
    virfinder_db
    additional_model_data
    viphog_db
    rvdb_db
    pvogs_db
    vogdb_db
    vpf_db
    ncbi_db
    imgvr_db
    checkv_db
}