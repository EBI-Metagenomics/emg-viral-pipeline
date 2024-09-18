/* 
 * Run virus detection tools and parse the predictions according to defined filters. 
*/

include { virsorter } from '../modules/local/virsorter' 
include { virfinder } from '../modules/local/virfinder' 
include { pprmeta   } from '../modules/local/pprmeta'

workflow DETECT {

    take:   
    assembly_renamed_length_filtered
    // Reference databases
    virsorter_db  
    virfinder_db
    pprmeta_git  

    main:

    renamed_ch = assembly_renamed_length_filtered.map {name, renamed_fasta, map, _, __ -> {
        tuple(name, renamed_fasta, map)
      }
    }

    length_filtered_ch = assembly_renamed_length_filtered.map { name, _, __, filtered_fasta, contig_number -> {
        tuple(name, filtered_fasta, contig_number)
      }
    }

    // virus detection --> VirSorter, VirFinder and PPR-Meta
    VIRSORTER( length_filtered_ch, virsorter_db)     
    VIRFINDER( length_filtered_ch, virfinder_db)
    PPRMETA( length_filtered_ch, pprmeta_git)

    // parsing predictions
    PARSE( length_filtered_ch.join( virfinder.out ).join( virsorter.out ).join( pprmeta.out ) )

    emit:
    PARSE.out.join(renamed_ch).transpose().map{ name, fasta, vs_meta, log, renamed_fasta, map -> tuple (name, fasta, map) }
}