/************************** 
* DATABASES
**************************/

/* Comment section:
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use.*/

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
    if (!params.cloudProcess) { checkvGetDB(); db = checkvGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.databases}/checkv", type: 'dir')
      if (db_preload.exists()) { db = db_preload }
      else  { checkvGetDB(); db = checkvGetDB.out } 
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