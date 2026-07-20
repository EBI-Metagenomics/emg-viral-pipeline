#!/usr/bin/env nextflow

include { samplesheetToList                 } from 'plugin/nf-schema'

/************************** 
* MODULES
**************************/
include { RESTORE as RESTORE_CATEGORY_FASTA } from '../modules/local/restore'
include { RESTORE as RESTORE_FILTERED_FASTA } from '../modules/local/restore'
include { MULTIQC                           } from '../modules/nf-core/multiqc'

/************************** 
* SUB WORKFLOWS
**************************/

include { ANNOTATE                          } from '../subworkflows/local/annotate'
include { DETECT                            } from '../subworkflows/local/detect'
include { DOWNLOAD_DATABASES                } from '../subworkflows/local/download_databases'
include { PLOT                              } from '../subworkflows/local/plot'
include { PREPROCESS                        } from '../subworkflows/local/preprocess'
include { PREDICT_PROTEINS                  } from '../subworkflows/local/protein_prediction'

include { SPLIT_PROTEINS                    } from '../modules/local/split_proteins'

/************************** 
* WORKFLOW ENTRY POINT
**************************/

/* 
Here the main workflow starts and runs the defined sub workflows. 
*/

workflow VIRIFY {

    /************************** 
    * INPUT CHANNELS 
    **************************/

    // mashmap input
    mashmap_ref_ch = Channel.empty()
    if (params.mashmap) {
        mashmap_ref_ch = Channel.fromPath(params.mashmap, checkIfExists: true)
    }

    // factor file input
    factor_file = Channel.empty()
    if (params.factor) {
        factor_file = file(params.factor, checkIfExists: true)
    }
    
    // multiqc inputs
    ch_multiqc_files = Channel.empty()
    ch_multiqc_config = Channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.fromPath("${projectDir}/assets/mgnify_logo.png")
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)

    samplesheet = Channel.fromList(samplesheetToList(params.samplesheet, "./assets/schema_input.json"))
    samplesheet
        .map { id, assembly, proteins_gff, proteins_faa ->
            tuple(
                ["id": id],
                assembly,
                proteins_gff ?: null,
                proteins_faa ?: null
            )
        }
        .set { input_assembly_proteins_ch }
   
    /**************************************************************/
    // check/ download all databases

    DOWNLOAD_DATABASES(
       params.pprmeta,
       params.pprmeta_download_link,
       params.virsorter,
       params.virsorter_download_link,
       params.virsorter2,
       params.virsorter2_download_link,
       params.virfinder,
       params.virfinder_download_link,
       params.viphog,
       params.viphog_download_link,
       params.ncbi,
       params.ncbi_download_link,
       params.checkv,
       params.checkv_download_link,
       params.rvdb,
       params.rvdb_download_link,
       params.pvogs,
       params.pvogs_download_link,
       params.vogdb,
       params.vogdb_download_link,
       params.vpf,
       params.vpf_download_link,
       params.imgvr,
       params.imgvr_download_link,
       params.meta,
       params.meta_download_link
    )

    /**************************************************************/

    // ----------- length filtering + rename fasta ------------------ //
    PREPROCESS(input_assembly_proteins_ch.map{ meta, assembly, _gff, _faa -> [meta, assembly] })

    mapfile = PREPROCESS.out.mapfile  // [meta, map.txt]

    filtered_and_renamed_assembly = PREPROCESS.out.filtered_and_renamed_contigs_fasta

    // Rename contigs to names before space for original assembly
    RESTORE_FILTERED_FASTA(filtered_and_renamed_assembly.join(mapfile), "temporary", "short")

    assembly_with_short_contignames = RESTORE_FILTERED_FASTA.out.map { meta, _name, fasta -> [meta, fasta] }

    // ----------- call proteins where not provided as input
    records_without_proteins = assembly_with_short_contignames
       .join(input_assembly_proteins_ch)
       .filter{ meta, name, fasta, gff, faa -> gff == null }
       .map{meta, name, fasta, gff, faa -> [meta, fasta] }
      
    PREDICT_PROTEINS(records_without_proteins)
    newly_predicted = records_without_proteins.join(PREDICT_PROTEINS.out.predicted_proteins)  // [meta, fasta, gff, faa]
    
    // join into one channel with all records having proteins predicted
    records_with_proteins = assembly_with_short_contignames
       .join(input_assembly_proteins_ch)
       .filter{ meta, name, fasta, gff, faa -> gff != null }
       .map{ meta, name, fasta, gff, faa -> [meta, fasta, gff, faa] }

    full_input = records_with_proteins.mix(newly_predicted)
    
    // ----------- define HC/LC/PP groups
    DETECT(
        filtered_and_renamed_assembly,
        DOWNLOAD_DATABASES.out.virsorter_downloaded_db,
        DOWNLOAD_DATABASES.out.virfinder_downloaded_db,
        DOWNLOAD_DATABASES.out.pprmeta_downloaded_db,
    )
    // output: (meta, fasta)

    // ----------- restore fasta files for each category fasta
    files_to_restore = DETECT.out.detect_output
        .join(mapfile)
        .map { meta, files, mapping_file ->
            // Ensure files is always a list
            def filesList = files instanceof List ? files : [files]
            [meta, filesList, mapping_file]
        }
        .transpose(by: 1)
    RESTORE_CATEGORY_FASTA(files_to_restore, "temporary", "short")
    category_fasta = RESTORE_CATEGORY_FASTA.out  // [meta, category_name, category_fasta]
    
    // ----------- split proteins into HC/LC/PP 
    protein_files_ch = full_input
        .map { meta, _assembly, proteins_gff, proteins_faa ->
            tuple(meta, proteins_gff, proteins_faa)
        }
        
    SPLIT_PROTEINS(category_fasta.groupTuple().join(protein_files_ch).transpose())

    proteins_ch = SPLIT_PROTEINS.out.fasta_proteins_gff  // [meta, category_name, category_fasta, category_faa, category_gff]
    
    // ----------- ANNOTATE
    // category_fastas is already per-category: (meta, set_name, fasta, faa, gff)
    // assembly_with_short_contignames is passed separately as a per-sample channel

    ANNOTATE(
        proteins_ch,
        assembly_with_short_contignames,
        DOWNLOAD_DATABASES.out.viphog_downloaded_db,
        DOWNLOAD_DATABASES.out.ncbi_downloaded_db,
        DOWNLOAD_DATABASES.out.rvdb_downloaded_db,
        DOWNLOAD_DATABASES.out.pvogs_downloaded_db,
        DOWNLOAD_DATABASES.out.vogdb_downloaded_db,
        DOWNLOAD_DATABASES.out.vpf_downloaded_db,
        DOWNLOAD_DATABASES.out.imgvr_downloaded_db,
        DOWNLOAD_DATABASES.out.meta_downloaded_db,
        DOWNLOAD_DATABASES.out.checkv_downloaded_db,
        factor_file,
        mashmap_ref_ch,
    )

    // ----------- PLOT 
    PLOT(
        ANNOTATE.out.assign_output,
        ANNOTATE.out.chromomap,
    )

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        false,
        false,
    )
}
