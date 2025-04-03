//visuals

include { GENERATE_KRONA_TABLE     } from '../../modules/local/krona' 
include { GENERATE_SANKEY_TABLE    } from '../../modules/local/sankey'
include { GENERATE_CHROMOMAP_TABLE } from '../../modules/local/chromomap'
include { KRONA                    } from '../../modules/local/krona'
include { SANKEY                   } from '../../modules/local/sankey'
include { CHROMOMAP                } from '../../modules/local/chromomap'
include { BALLOON                  } from '../../modules/local/balloon'

workflow PLOT {
/*
Plot results. Basically runs krona and sankey. ChromoMap and Balloon are still experimental features and should be used with caution. 
*/
    take:
      assigned_lineages_ch
      annotated_proteins_ch

    main:
        // krona
        combined_assigned_lineages_ch = assigned_lineages_ch.groupTuple().map { tuple(it[0], 'all', it[2]) }.concat(assigned_lineages_ch)
        KRONA(
          GENERATE_KRONA_TABLE(combined_assigned_lineages_ch)
        )

        // sankey
        if (workflow.profile != 'conda') {
          SANKEY(
            GENERATE_SANKEY_TABLE(GENERATE_KRONA_TABLE.out)
         )
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
