//visuals

include { TAXONOMY_COUNTS_TABLE    } from '../../modules/local/taxonomy_counts'
include { GENERATE_SANKEY_TABLE    } from '../../modules/local/sankey'
include { GENERATE_CHROMOMAP_TABLE } from '../../modules/local/chromomap'
include { KRONA                    } from '../../modules/local/krona'
include { SANKEY                   } from '../../modules/local/sankey'
include { CHROMOMAP                } from '../../modules/local/chromomap'
include { BALLOON                  } from '../../modules/local/balloon'

/*
 * Plot results. Basically runs krona and sankey. ChromoMap and Balloon are still experimental features and should be used with caution. 
*/
workflow PLOT {

  take:
  assigned_lineages_ch
  annotated_proteins_ch

  main:
  // general taxonomy counts
  combined_assigned_lineages_ch = assigned_lineages_ch.groupTuple().map { tuple(it[0], 'all', it[2]) }.concat(assigned_lineages_ch)
  TAXONOMY_COUNTS_TABLE(combined_assigned_lineages_ch)

  // krona (without undefined taxa)
  KRONA(
    TAXONOMY_COUNTS_TABLE.out.tsv
  )

  // sankey
  if (workflow.profile != 'conda') {
    GENERATE_SANKEY_TABLE(TAXONOMY_COUNTS_TABLE.out.tsv)

    SANKEY(GENERATE_SANKEY_TABLE.out.sankey_filtered_json)
  }

  // chromomap
  if (workflow.profile != 'conda' && params.chromomap) {
    combined_annotated_proteins_ch = annotated_proteins_ch.groupTuple().map { tuple(it[0], 'all', it[2], it[3]) }.concat(annotated_proteins_ch)
    CHROMOMAP(
      GENERATE_CHROMOMAP_TABLE(combined_annotated_proteins_ch)
    )
  }

  // balloon plot
  if (params.balloon) {
    BALLOON(combined_assigned_lineages_ch)
  }
}
