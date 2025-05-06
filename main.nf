/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { helpMSG                } from './modules/local/help'
include { printMetadataV4Warning } from './modules/local/warnings'
include { validateParameters ; paramsHelp ; paramsSummaryLog } from 'plugin/nf-schema'

// ------------------------------
// WORKFLOW: Run main ebi-metagenomics/emg-viral-pipeline analysis pipeline
// ------------------------------

include { VIRIFY                 } from './workflows/virify'

workflow {

  if (params.help) {
    helpMSG()
    exit(0)
  }

  validateParameters()

  log.info(paramsSummaryLog(workflow))

  if (params.meta_version == "v4") {
    printMetadataV4Warning()
  }

  VIRIFY()
}
