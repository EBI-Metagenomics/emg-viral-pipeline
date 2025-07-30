/* 
 * Run virus detection tools and parse the predictions according to defined filters. 
*/

include { VIRSORTER                                                  } from '../../modules/local/virsorter'
include { VIRSORTER2                                                 } from '../../modules/local/virsorter2'
include { VIRFINDER                                                  } from '../../modules/local/virfinder'
include { PPRMETA                                                    } from '../../modules/local/pprmeta'
include { PARSE                                                      } from '../../modules/local/parse'
include { CONCATENATE_FILES as CONCATENATE_FILES_SCORE               } from '../../modules/local/utils'
include { CONCATENATE_FILES as CONCATENATE_FILES_BOUNDARY            } from '../../modules/local/utils'
include { CONCATENATE_FILES as CONCATENATE_FILES_FA                  } from '../../modules/local/utils'

workflow DETECT {
  take:
  renamed_assembly_and_contigs_count
  virsorter_db
  virfinder_db
  pprmeta_git

  main:

  // virus detection --> VirSorter/VirSorter2, VirFinder and PPR-Meta

  virsorter_output = Channel.empty()

  if (params.use_virsorter_v1) {

    VIRSORTER(renamed_assembly_and_contigs_count, virsorter_db)

    virsorter_output = VIRSORTER.out
  }
  else {

    // chunk fasta by 500Mb
    chunked_ch = renamed_assembly_and_contigs_count.flatMap { meta, fasta, contigs_count ->
      def chunks = fasta.splitFasta(file: true, size: 500.MB)
      chunks.collect { chunk ->
        return tuple(meta, chunk, contigs_count)
      }
    }
    VIRSORTER2(chunked_ch, virsorter_db)

    CONCATENATE_FILES_SCORE(
      VIRSORTER2.out.score_tsv.groupTuple(),
      "final-viral-score.tsv",
    )
    collected_score = CONCATENATE_FILES_SCORE.out.concatenated_result

    CONCATENATE_FILES_BOUNDARY(
      VIRSORTER2.out.boundary_tsv.groupTuple(),
      "final-viral-boundary.tsv",
    )
    collected_boundary = CONCATENATE_FILES_BOUNDARY.out.concatenated_result

    CONCATENATE_FILES_FA(
      VIRSORTER2.out.combined_fa.groupTuple(),
      "final-viral-combined.fa",
    )
    collected_fa = CONCATENATE_FILES_FA.out.concatenated_result

    virsorter_output = collected_score
      .join(collected_boundary)
      .join(collected_fa)
      .map { meta, score, boundary, fa ->
        return tuple(meta, [score, boundary, fa])
      }
  }

  VIRFINDER(renamed_assembly_and_contigs_count, virfinder_db)

  PPRMETA(renamed_assembly_and_contigs_count, pprmeta_git)

  // parsing predictions
  PARSE(renamed_assembly_and_contigs_count.join(VIRFINDER.out).join(virsorter_output).join(PPRMETA.out))

  emit:
  detect_output = PARSE.out.map { meta, fasta, _vs_meta, _log -> tuple(meta, fasta) }.transpose()
}
