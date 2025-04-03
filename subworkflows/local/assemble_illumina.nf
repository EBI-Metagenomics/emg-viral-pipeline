/* 
Optional assembly step, not fully implemented and tested. 
*/

include { FASTP                   } from '../../modules/nf-core/fastp'
include { FASTQC as FASTQC_BEFORE } from '../../modules/nf-core/fastqc'
include { FASTQC as FASTQC_AFTER  } from '../../modules/nf-core/fastqc'
include { SPADES                  } from '../../modules/nf-core/spades' 

workflow ASSEMBLE_ILLUMINA {
    take:    reads

    main:
        // QC before filtering
        FASTQC_BEFORE(reads)
        
        // trimming
        FASTP(
           reads, 
           [], 
           false, 
           false, 
           false
        )
        
        // QC after filtering
        FASTQC_AFTER(FASTP.out.reads)
 
        // assembly
        SPADES(
          FASTP.out.reads.map { meta, reads -> [meta, reads, [], []] }, 
          [], 
          []
        )

        ch_multiqc_files = Channel.empty() 
        ch_multiqc_files = ch_multiqc_files.mix( FASTQC_BEFORE.out.zip.collect{it[1]}.ifEmpty([]) )
        ch_multiqc_files = ch_multiqc_files.mix( FASTP.out.json.collect{it[1]}.ifEmpty([]) )
        ch_multiqc_files = ch_multiqc_files.mix( FASTQC_AFTER.out.zip.collect{it[1]}.ifEmpty([]) )

    emit:
        assembly         = SPADES.out.contigs
        ch_multiqc_files = ch_multiqc_files
}