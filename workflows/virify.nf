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

    input_ch = Channel.empty()
    mashmap_ref_ch = Channel.empty()
    factor_file = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_multiqc_config = Channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.fromPath("${projectDir}/assets/mgnify_logo.png")
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)

    groupInputs = { id, assembly, proteins_gff, proteins_faa ->
        if (params.use_proteins && proteins_gff && proteins_faa) {
            return tuple(
                ["id": id],
                assembly,
                proteins_gff,
                proteins_faa
            )
        }
        else {
            return tuple(
                ["id": id],
                assembly,
            )
        }
    }
    samplesheet = Channel.fromList(samplesheetToList(params.samplesheet, "./assets/schema_input.json"))
    input_ch = samplesheet.map(groupInputs)

    // mashmap input
    if (params.mashmap) {
        mashmap_ref_ch = Channel.fromPath(params.mashmap, checkIfExists: true)
    }

    // factor file input
    if (params.factor) {
        factor_file = file(params.factor, checkIfExists: true)
    }

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

    proteins_ch = Channel.empty()

    if (params.use_proteins) {
        assembly_ch = input_ch.map { meta, assembly, _proteins_gff, _proteins_faa -> tuple(meta, assembly) }
    }
    else {
        assembly_ch = input_ch
    }

    // ----------- length filtering + rename fasta ------------------ //
    PREPROCESS(assembly_ch)

    mapfile = PREPROCESS.out.mapfile

    filtered_and_renamed_assembly = PREPROCESS.out.filtered_and_renamed_contigs_fasta

    // Rename contigs to names before space for original assembly
    RESTORE_FILTERED_FASTA(filtered_and_renamed_assembly.join(mapfile), "temporary", "short")

    assembly_with_short_contignames = RESTORE_FILTERED_FASTA.out.map { meta, _name, fasta -> [meta, fasta] }

    // ----------- if --onlyannotate - skip DETECT step
    if (params.onlyannotate) {
        // use filtered fasta with short names
        category_fasta = RESTORE_FILTERED_FASTA.out
    }
    else {
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
        category_fasta = RESTORE_CATEGORY_FASTA.out
    }

    // ----------- split proteins into HC/LC/PP - if provided
    if (params.use_proteins) {

        faa = input_ch.map { meta, _assembly, proteins_gff, proteins_faa -> tuple(meta, proteins_gff, proteins_faa) }

        SPLIT_PROTEINS(category_fasta.groupTuple().join(faa).transpose())

        proteins_ch = SPLIT_PROTEINS.out.fasta_proteins_gff
    }

    // ----------- ANNOTATE
    // category_fastas is already per-category: (meta, set_name, fasta) or (meta, set_name, fasta, faa)
    // assembly_with_short_contignames is passed separately as a per-sample channel
    annotate_input = params.use_proteins ? proteins_ch : category_fasta

    ANNOTATE(
        annotate_input,
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
