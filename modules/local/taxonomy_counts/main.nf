process TAXONOMY_COUNTS_TABLE {
    label 'process_single'
    tag "${meta.id} ${set_name}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'
    
    input:
      tuple val(meta), val(set_name), path(tbl)
    
    output:
      tuple val(meta), val(set_name), path("*.counts.tsv"), emit: tsv
    
    script:
    """
    if [[ "${set_name}" == "all" ]]; then
      grep contig_ID *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq > ${meta.id}.tmp
      grep -v "contig_ID" *.tsv | awk 'BEGIN{FS=":"};{print \$2}' | uniq >> ${meta.id}.tmp
      cp ${meta.id}.tmp ${meta.id}.tsv
      generate_counts_table.py -f ${meta.id}.tsv -o ${meta.id}.counts.tsv
    else
      generate_counts_table.py -f ${tbl} -o ${set_name}.counts.tsv
    fi
    """
}

// output example:
// 4	undefined
// 2	Viruses	Heunggongvirae	Uroviricota	undefined_subphylum_Uroviricota	Caudoviricetes	undefined_order_Caudoviricetes	undefined_suborder_Caudoviricetes	Autographiviridae	undefined_subfamily_Autographiviridae	Pradovirus
// 1	Viruses	Heunggongvirae	Uroviricota	undefined_subphylum_Uroviricota	Caudoviricetes	undefined_order_Caudoviricetes	undefined_suborder_Caudoviricetes	undefined_family_Caudoviricetes	Guernseyvirinae
// 1	Viruses	Bamfordvirae	Nucleocytoviricota	undefined_subphylum_Nucleocytoviricota	Megaviricetes	Imitervirales	undefined_suborder_Imitervirales	Mimiviridae	Klosneuvirinae
