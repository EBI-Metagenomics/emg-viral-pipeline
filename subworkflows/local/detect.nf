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
      // chunk fasta by 10Mb
      chunked_ch = length_filtered_ch.flatMap{ meta, fasta, value ->
          def chunks = fasta.splitFasta(file: true, size: 10.MB);
          chunks.collect{ chunk ->
             return tuple(meta, chunk, value);
          }
      }
      VIRSORTER2(chunked_ch, virsorter_db)
      collected_score = VIRSORTER2.out.score_tsv.flatMap{meta, tsv -> 
         (meta, tsv.collectFile(name:"final-viral-score.tsv", keepHeader:true, skip:1))
      }
      collected_boundary = VIRSORTER2.out.boundary_tsv.flatMap{meta, tsv -> 
         (meta, tsv.collectFile(name:"final-viral-boundary.tsv", keepHeader:true, skip:1))
      }    
      collected_fa = VIRSORTER2.out.combined_fa.flatMap{meta, fa -> 
         (meta, fa.collectFile(name:"final-viral-combined.fa"))
      }    
      virsorter_output = collected_score.join(collected_boundary).join(collected_fa).map {meta, score, boundary, fa -> 
          (meta, [score, boundary, fa])}
    }
    
         
    VIRFINDER( length_filtered_ch, virfinder_db)
    
    PPRMETA( length_filtered_ch, pprmeta_git)

    // parsing predictions
    PARSE( length_filtered_ch.join( VIRFINDER.out ).join( virsorter_output ).join( PPRMETA.out ) )

    emit:
    detect_output = PARSE.out.join(renamed_ch).transpose().map{ meta, fasta, vs_meta, log, renamed_fasta, map -> tuple (meta, fasta, map) }
}