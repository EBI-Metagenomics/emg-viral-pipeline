process checkV {
        publishDir "${params.output}/${name}/${params.checkvdir}/", mode: 'copy' , pattern: "${confidence_set_name}"
        publishDir "${params.output}/${name}/${params.checkvdir}/", mode: 'copy' , pattern: "*.tsv"

        errorStrategy 'ignore'
        label 'checkV'
    input:
        tuple val(name), val(confidence_set_name), file(fasta)
        file(database)
        file(filtered_fasta)
    output:
        tuple val(name), val(confidence_set_name), path("${confidence_set_name}_quality_summary.tsv"), path("${confidence_set_name}/") optional true
    script:
        """
        if [[ ${fasta} == *"prophage"* ]]; then
          grep '>' ${fasta} | cut -d' ' -f1 > prophage_contigs
          seqtk subseq ${filtered_fasta} prophage_contigs > prophage_contigs.fasta
          checkv end_to_end prophage_contigs.fasta -d ${database} -t ${task.cpus} ${confidence_set_name} 
        else;
          checkv end_to_end ${fasta} -d ${database} -t ${task.cpus} ${confidence_set_name} 
        fi
        cp ${confidence_set_name}/quality_summary.tsv ${confidence_set_name}_quality_summary.tsv 
        """
    stub:
        """
        mkdir negative_result_${confidence_set_name}.tsv
        echo "contig_id	contig_length	genome_copies	gene_count	viral_genes	host_genes	checkv_quality	miuvig_quality	completeness	completeness_method	contamination	provirus	termini	warnings" > ${confidence_set_name}_quality_summary.tsv
        echo "pos_phage_0	146647	1.0	243	141	1	High-quality	High-quality	97.03	AAI-based	0.0	No" >> ${confidence_set_name}_quality_summary.tsv   
        """
}
//, file("negative_result_${name}.tsv") optional true
