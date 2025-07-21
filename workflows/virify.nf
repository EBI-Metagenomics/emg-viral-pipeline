#!/usr/bin/env nextflow

include { samplesheetToList            } from 'plugin/nf-schema'

/************************** 
* MODULES
**************************/
include { RESTORE as RESTORE_FOR_ONLY_ANNOTATE } from '../modules/local/restore'
include { RESTORE as RESTORE_CATEGORY_FASTA    } from '../modules/local/restore'
include { RESTORE as RESTORE_FILTERED_FASTA    } from '../modules/local/restore'
include { MULTIQC                              } from '../modules/nf-core/multiqc'

/************************** 
* SUB WORKFLOWS
**************************/

include { ASSEMBLE_ILLUMINA            } from '../subworkflows/local/assemble_illumina'
include { ANNOTATE                     } from '../subworkflows/local/annotate'
include { DETECT                       } from '../subworkflows/local/detect'
include { DOWNLOAD_DATABASES           } from '../subworkflows/local/download_databases'
include { PLOT                         } from '../subworkflows/local/plot'
include { PREPROCESS                   } from '../subworkflows/local/preprocess'
include { SPLIT_PROTEINS_BY_CATEGORIES } from '../subworkflows/local/split_proteins_by_categories'

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
  ch_multiqc_config = Channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
  ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
  ch_multiqc_logo = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.fromPath("${projectDir}/assets/mgnify_logo.png")
  ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)

  if (params.samplesheet) {
    groupInputs = { id, assembly, fq1, fq2, proteins ->
      if (fq1 == []) {
        if (params.use_proteins && proteins) {
          return tuple(
            ["id": id],
            assembly,
            proteins,
          )
        }
        else {
          return tuple(
            ["id": id],
            assembly,
          )
        }
      }
      else {
        if (params.assemble) {
          return tuple(
            ["id": id],
            [fq1, fq2],
          )
        }
        else {
          exit(1, "input missing, use [--assemble] flag with raw reads")
        }
      }
    }
    samplesheet = Channel.fromList(samplesheetToList(params.samplesheet, "./assets/schema_input.json"))
    input_ch = samplesheet.map(groupInputs)
  }

  // one sample of assembly
  if (params.fasta) {
    input_ch = Channel.fromPath(params.fasta, checkIfExists: true)
      .map { file -> tuple(["id": file.simpleName], file) }
  }

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

  DOWNLOAD_DATABASES()

  /**************************************************************/

  assembly_ch = Channel.empty()
  proteins_ch = Channel.empty()

  // ----------- if --assemble specified - assemble reads first
  if (params.assemble) {
    ASSEMBLE_ILLUMINA(input_ch)
    assembly_ch = ASSEMBLE_ILLUMINA.out.assembly
  }
  else {
    if (params.use_proteins) {
      assembly_ch = input_ch.map { meta, assembly, _proteins -> tuple(meta, assembly) }
    }
    else {
      assembly_ch = input_ch
    }
  }

  // ----------- rename fasta + length filtering
  // out: (meta, renamed_fasta, map, filtered_fasta, env)
  PREPROCESS(assembly_ch)
  mapfile = PREPROCESS.out.preprocessed_data.map { name, _renamed_fasta, map, _filtered_fasta, _contig_number -> tuple(name, map) }
  filtered_assembly = PREPROCESS.out.preprocessed_data.map { name, _renamed_fasta, _map, filtered_fasta, _contig_number -> tuple(name, filtered_fasta) }
  renamed_assembly_and_contig_number = PREPROCESS.out.preprocessed_data.map { name, renamed_fasta, _map, _filtered_fasta, contig_number -> tuple(name, renamed_fasta, contig_number) }
  
  // ----------- if --onlyannotate - skip DETECT step
  if (params.onlyannotate) {
    // use filtered fasta, need to convert original names into short names
    RESTORE_FOR_ONLY_ANNOTATE(filtered_assembly.join(mapfile), "original", "short")
    category_fasta = RESTORE_FOR_ONLY_ANNOTATE.out
    assembly_with_short_contignames = RESTORE_FOR_ONLY_ANNOTATE.out
  }
  else {
    DETECT(
      renamed_assembly_and_contig_number,
      DOWNLOAD_DATABASES.out.virsorter_db,
      DOWNLOAD_DATABASES.out.virfinder_db,
      DOWNLOAD_DATABASES.out.pprmeta_git,
    )   // output: (meta, fasta)
    
    // ----------- restore fasta files for each category fasta
    files_to_restore = DETECT.out.detect_output.combine(mapfile)
    .filter { fasta_meta, fasta_file, map_meta, map_file ->
        fasta_meta.id == map_meta.id
    }
    .map { fasta_meta, fasta_file, map_meta, map_file ->
        [fasta_meta, fasta_file, map_file]
    }
    RESTORE_CATEGORY_FASTA(files_to_restore, "temporary", "short")
    category_fasta = RESTORE_CATEGORY_FASTA.out  // (meta, type(HC/LC/PP), fasta)
    
    // Rename contigs to names before space for original assembly
    RESTORE_FILTERED_FASTA(filtered_assembly.join(mapfile), "temporary", "short")
    assembly_with_short_contignames = RESTORE_FILTERED_FASTA.out
  }

  // ----------- split proteins into HC/LC/PP - if provided
  if (params.use_proteins) {

    faa = input_ch.map { meta, _assembly, proteins -> tuple(meta, proteins) }

    SPLIT_PROTEINS_BY_CATEGORIES(category_fasta.groupTuple().join(faa).transpose())

    proteins_ch = SPLIT_PROTEINS_BY_CATEGORIES.out.splitted_proteins
  }

  // ----------- ANNOTATE
  if (params.use_proteins) {
    // (meta, [type](HC/LC/PP), [fasta], [faa], original_assembly) -> [(meta, type, fasta, faa, original_assembly)]
    annotate_input = proteins_ch
      .groupTuple()
      .join(assembly_with_short_contignames)
      .flatMap { meta, types, fasta_paths, faa_paths, original_contigs ->
        types
          .indexed()
          .collect { i, type ->
            tuple(meta, type, fasta_paths[i], faa_paths[i], original_contigs)
          }
      }
  }
  else {
    // (meta, [type](HC/LC/PP), [fasta], original_assembly) -> [(meta, type, fasta, original_assembly)]
    annotate_input = category_fasta
      .groupTuple()
      .join(assembly_with_short_contignames)
      .flatMap { meta, types, fasta_paths, original_contigs ->
        types
          .indexed()
          .collect { i, type ->
            tuple(meta, type, fasta_paths[i], original_contigs)
          }
      }
  }

  ANNOTATE(
    annotate_input,
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
    mashmap_ref_ch,
  )

  // ----------- PLOT 
  PLOT(
    ANNOTATE.out.assign_output,
    ANNOTATE.out.chromomap,
  )

  if (params.assemble) {

    ch_multiqc_files = ASSEMBLE_ILLUMINA.out.ch_multiqc_files

    MULTIQC(
      ch_multiqc_files.collect(),
      ch_multiqc_config.toList(),
      ch_multiqc_custom_config.toList(),
      ch_multiqc_logo.toList(),
      false,
      false,
    )
  }
}
