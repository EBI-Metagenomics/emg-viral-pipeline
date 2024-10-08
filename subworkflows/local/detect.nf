/* 
 * Run virus detection tools and parse the predictions according to defined filters. 
*/

include { VIRSORTER  } from '../../modules/local/virsorter' 
include { VIRSORTER2 } from '../../modules/local/virsorter2' 
include { VIRFINDER  } from '../../modules/local/virfinder' 
include { PPRMETA    } from '../../modules/local/pprmeta'
include { PARSE      } from '../../modules/local/parse'

workflow DETECT {

    take:   
    assembly_renamed_length_filtered
    // Reference databases
    virsorter_db  
    virfinder_db
    pprmeta_git  

    main:

    renamed_ch = assembly_renamed_length_filtered.map { 
                meta, renamed_fasta, map, _, __ -> tuple(meta, renamed_fasta, map)
    }

    length_filtered_ch = assembly_renamed_length_filtered.map { 
               meta, _, __, filtered_fasta, contig_number -> tuple(meta, filtered_fasta, contig_number)
    }

    // virus detection --> VirSorter/VirSorter2, VirFinder and PPR-Meta
    
    virsorter_output = Channel.empty()
    if (params.use_virsorter_v1) {
      VIRSORTER( length_filtered_ch, virsorter_db)
      virsorter_output = VIRSORTER.out
    }
    else {
      VIRSORTER2( length_filtered_ch, virsorter_db)
      virsorter_output = VIRSORTER2.out
    }
         
    VIRFINDER( length_filtered_ch, virfinder_db)
    
    PPRMETA( length_filtered_ch, pprmeta_git)

    // parsing predictions
    PARSE( length_filtered_ch.join( VIRFINDER.out ).join( virsorter_output ).join( PPRMETA.out ) )

    emit:
    detect_output = PARSE.out.join(renamed_ch).transpose().map{ meta, fasta, vs_meta, log, renamed_fasta, map -> tuple (meta, fasta, map) }
}