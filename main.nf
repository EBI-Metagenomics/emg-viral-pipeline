#!/usr/bin/env nextflow

import groovy.json.JsonSlurper

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { printMetadataV4Warning } from './modules/local/warnings'
include { validateParameters; paramsHelp; paramsSummaryLog; } from 'plugin/nf-schema'

if (params.help) {
   log.info paramsHelp("nextflow run ebi-metagenomics/emg-viral-pipeline --help")
   exit 0
}

validateParameters()

log.info paramsSummaryLog(workflow)

if (params.meta_version == "v4") { printMetadataV4Warning() }

// check input
if (params.illumina == '' &&  params.fasta == '' ) {
  exit 1, "input missing, use [--illumina] or [--fasta]"}
  
// ------------------------------
// WORKFLOW: Run main ebi-metagenomics/emg-viral-pipeline analysis pipeline
// ------------------------------

include { VIRIFY } from './workflows/virify'

workflow {
    VIRIFY ()
}
