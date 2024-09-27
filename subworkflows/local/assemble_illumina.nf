/* 
Optional assembly step, not fully implemented and tested. 
*/

include { FASTP   } from '../../modules/local/fastp'
include { FASTQC  } from '../../modules/local/fastqc'
include { MULTIQC } from '../../modules/local/multiqc' 
include { SPADES  } from '../../modules/local/spades' 

workflow ASSEMBLE_ILLUMINA {
    take:    reads

    main:
        // trimming
        FASTP(reads)
 
        // read QC
        MULTIQC(FASTQC(FSATP.out))

        // assembly
        SPADES(FASTP.out)

    emit:
        assembly = SPADES.out
}