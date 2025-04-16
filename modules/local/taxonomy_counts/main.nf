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
    export accession="${meta.id}"
    if [ "${set_name}" != "all" ]; then
      export accession="${set_name}"
    fi
      
    generate_counts_table.py -f ${tbl} -o \${accession}.counts.tsv
    """
}

// output example:
// 4	undefined
// 2	Viruses	Heunggongvirae	Uroviricota	undefined_subphylum_Uroviricota	Caudoviricetes	undefined_order_Caudoviricetes	undefined_suborder_Caudoviricetes	Autographiviridae	undefined_subfamily_Autographiviridae	Pradovirus
// 1	Viruses	Heunggongvirae	Uroviricota	undefined_subphylum_Uroviricota	Caudoviricetes	undefined_order_Caudoviricetes	undefined_suborder_Caudoviricetes	undefined_family_Caudoviricetes	Guernseyvirinae
// 1	Viruses	Bamfordvirae	Nucleocytoviricota	undefined_subphylum_Nucleocytoviricota	Megaviricetes	Imitervirales	undefined_suborder_Imitervirales	Mimiviridae	Klosneuvirinae
