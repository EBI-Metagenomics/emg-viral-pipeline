process plot_contig_map {
      errorStrategy { task.exitStatus = 1 ? 'ignore' :  'terminate' }
      publishDir "${params.output}/${name}/${params.plotdir}/", mode: 'copy', pattern: "${set_name}_mapping_results"
      publishDir "${params.output}/${name}/${params.finaldir}/annotation/", mode: 'copy', pattern: "${set_name}_prot_ann_table_filtered.tsv"
      label 'plot_contig_map'

    input:
      tuple val(name), val(set_name), file(tab)
    
    output:
      tuple val(name), val(set_name), file("${set_name}_mapping_results"), file("${set_name}_prot_ann_table_filtered.tsv")
    
    script:
    """
  	# get only contig IDs that have at least one annotation hit
    cat ${tab} | sed 's/|/VIRIFY/g' > virify.tmp 
	  IDS=\$(awk 'BEGIN{FS="\\t"};{if(\$6!="No hit"){print \$1}}' virify.tmp | sort | uniq | grep -v Contig)
	  head -1 ${tab} > ${set_name}_prot_ann_table_filtered.tsv
	  for ID in \$IDS; do
		  awk -v id="\$ID" '{if(id==\$1){print \$0}}' virify.tmp >> ${set_name}_prot_ann_table_filtered.tsv
	  done
    sed -i 's/VIRIFY/|/g' ${set_name}_prot_ann_table_filtered.tsv
    mkdir -p ${set_name}_mapping_results
    cp ${set_name}_prot_ann_table_filtered.tsv ${set_name}_mapping_results/
    make_viral_contig_map.R -o ${set_name}_mapping_results -t ${set_name}_prot_ann_table_filtered.tsv
    """
}

/* INPUT LOOKS LIKE
Contig	CDS_ID	Start	End	Direction	Best_hit	Abs_Evalue_exp	Label
pos.phage.0	pos.phage.0_1	265	537	1	No hit	NA
pos.phage.0	pos.phage.0_63	24589	25578	-1	ViPhOG17126.faa	11	Batrachovirus
pos.phage.0	pos.phage.0_64	25578	25991	-1	No hit	NA
pos.phage.0	pos.phage.0_81	33714	34214	-1	ViPhOG602.faa	30	Myoviridae
pos.phage.0	pos.phage.0_82	34227	34370	-1	No hit	NA
*/

