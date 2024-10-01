#!/usr/bin/env nextflow

/************************** 
* INPUT CHANNELS 
**************************/

illumina_input_ch = Channel.empty()
fasta_input_ch    = Channel.empty()
mashmap_ref_ch    = Channel.empty()
factor_file       = Channel.empty()

// illumina reads input & --list support
if (params.illumina && params.list) { 
   illumina_input_ch = Channel.fromPath( params.illumina, checkIfExists: true )
     .splitCsv()
     .map { row -> ["${row[0]}", [file("${row[1]}"), file("${row[2]}")]] }
}
else if (params.illumina) { 
  illumina_input_ch = Channel.fromFilePairs( params.illumina , checkIfExists: true )
}

// direct fasta input w/o assembly support & --list support
if (params.fasta && params.list) { 
   fasta_input_ch = Channel.fromPath( params.fasta, checkIfExists: true )
      .splitCsv()
      .map { row -> ["${row[0]}", file("${row[1]}")] }
}
else if (params.fasta) { 
   fasta_input_ch = Channel.fromPath( params.fasta, checkIfExists: true)
      .map { file -> tuple(file.simpleName, file) }
}

// mashmap input
if (params.mashmap) { 
   mashmap_ref_ch = Channel.fromPath( params.mashmap, checkIfExists: true)
}
      
// factor file input
if (params.factor) { 
   factor_file = file( params.factor, checkIfExists: true) 
}

/************************** 
* SUB WORKFLOWS
**************************/

include { ASSEMBLE_ILLUMINA  } from '../subworkflows/local/assemble_illumina'
include { ANNOTATE           } from '../subworkflows/local/annotate'
include { DETECT             } from '../subworkflows/local/detect'
include { DOWNLOAD_DATABASES } from '../subworkflows/local/download_databases'
include { PLOT               } from '../subworkflows/local/plot'
include { POSTPROCESS        } from '../subworkflows/local/postprocess'
include { PREPROCESS         } from '../subworkflows/local/preprocess'

/************************** 
* WORKFLOW ENTRY POINT
**************************/

/* 
Here the main workflow starts and runs the defined sub workflows. 
*/

workflow VIRIFY {

    /**************************************************************/
    // check/ download all databases
    
    DOWNLOAD_DATABASES()

    /**************************************************************/
    
    assembly_ch = Channel.empty()
    
    // ----------- if --illumina specified - assemble reads first
    if (params.illumina) { 
      ASSEMBLE_ILLUMINA( illumina_input_ch )
      assembly_ch = ASSEMBLE_ILLUMINA.out.assembly
    }
    else {
      assembly_ch = fasta_input_ch
    }
    
    // ----------- rename fasta + length filtering
    PREPROCESS( assembly_ch )  
 
    // ----------- if --onlyannotate - skip DETECT step
    postprocess_input_ch = Channel.empty()
    
    if (params.onlyannotate) {
       postprocess_input_ch = PREPROCESS.out.preprocessed_data.map{name, renamed_fasta, map, filtered_fasta, contig_number -> tuple(name, filtered_fasta, map)}
    }
    else {
       DETECT(
         PREPROCESS.out.preprocessed_data, 
         DOWNLOAD_DATABASES.out.virsorter_db, 
         DOWNLOAD_DATABASES.out.virfinder_db, 
         DOWNLOAD_DATABASES.out.pprmeta_git
      )
      postprocess_input_ch = DETECT.out
    }

    // ----------- POSTPROCESS: restore fasta file
    POSTPROCESS(postprocess_input_ch)
    
    // ----------- ANNOTATE
    ANNOTATE(
        assembly_ch,
        POSTPROCESS.out.restored_fasta,
        DOWNLOAD_DATABASES.out.viphog_db,
        DOWNLOAD_DATABASES.out.ncbi_db,
        DOWNLOAD_DATABASES.out.rvdb_db,
        DOWNLOAD_DATABASES.out.pvogs_db,
        DOWNLOAD_DATABASES.out.vogdb_db,
        DOWNLOAD_DATABASES.out.vpf_db,
        DOWNLOAD_DATABASES.out.imgvr_db,
        DOWNLOAD_DATABASES.out.additional_model_data,
        DOWNLOAD_DATABASES.out.checkv_db,
        factor_file,
        mashmap_ref_ch
    )
    
    // ----------- PLOT 
    PLOT( 
       ANNOTATE.out.assign_output,
       ANNOTATE.out.chromomap
    )
}

