#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: virify

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  input_fasta_file:  # input assembly
    type: File
    format: edam:format_1929
  fasta_length_filter:
    type: float
    default: 1.0
  virsorter_virome:
    type: boolean
    default: false
    doc: |
      Set this parameter if the input fasta is mostly viral.
      See: https://github.com/simroux/VirSorter/issues/50
  # == Databases == #
  virsorter_data_dir:
    type: Directory
    doc: |
      VirSorter supporting database files.
  virfinder_model:
    type: File
    doc: |
        VirFinder model for predicting prokaryotic phages and eukaryotic viruses.
        Download: ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virfinder/VF.modEPV_k8.rda
  add_hmms_tsv:
    type: File
    format: edam:format_3475
    doc: |
        Additonal metadata tsv
  hmmdb:
    type: File
    doc: |
      HMMScan Viral HMM (databases/vpHMM/vpHMM_database.hmm).
  h3m:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3m)
  h3i:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3i)
  h3f:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3f)
  h3p:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3p)
  ncbi_tax_db_file:
    type: File
    doc: |
      ete3 NCBITaxa db https://github.com/etetoolkit/ete/blob/master/ete3/ncbi_taxonomy/ncbiquery.py
      http://etetoolkit.org/docs/latest/tutorial/tutorial_ncbitaxonomy.html
      This file was manually built and placed in the corresponding path (on databases)
  img_blast_database_dir:
    type: Directory
    doc: |
      Downloaded from:
      https://genome.jgi.doe.gov/portal/IMG_VR/IMG_VR.home.html
  checkv_database:
    type: Directory
    doc: |
      CheckV database version 1.0 - compatilble with CheckV 0.8.1
      Downloaded from:
      wget https://portal.nersc.gov/CheckV/checkv-db-v1.0.tar.gz
  # optional steps
  mashmap_reference_file:
    type: File?
    doc: |
      MashMap Reference file. Use MashMap to 

steps:
  fasta_rename:
    label: Rename contigs
    doc: |
      Rename contigs in fasta, this is required because some tools
      don't handle long names properly
    run: ./Tools/FastaRename/fasta_rename.cwl
    in:
      input: input_fasta_file
    out:
      - renamed_fasta
      - name_map

  length_filter:
    label: Filter contigs
    doc: Default length 1kb https://github.com/EBI-Metagenomics/emg-virify-scripts/issues/6
    run: ./Tools/LengthFiltering/length_filtering.cwl
    in:
      fasta_file: fasta_rename/renamed_fasta
      length: fasta_length_filter
    out:
      - filtered_contigs_fasta

  virfinder:
    label: VirFinder
    run: ./Tools/VirFinder/virfinder.cwl
    in:
      fasta_file: length_filter/filtered_contigs_fasta
      model: virfinder_model
    out:
      - virfinder_output

  virsorter:
    label: VirSorter
    run: ./Tools/VirSorter/virsorter.cwl
    in:
      fasta_file: length_filter/filtered_contigs_fasta
      data_dir: virsorter_data_dir
      virome_decontamination_mode: virsorter_virome
    out:
      - virsorter_fastas 

  pprmeta:
    label: PPR-Meta
    run: ./Tools/PPRMeta/pprmeta.cwl
    in:
      fasta_file: length_filter/filtered_contigs_fasta
    out:
      - pprmeta_output

  parse_pred_contigs:
    label: Parse predictions
    run: ./Tools/ParsingPredictions/parse_viral_pred.cwl
    in:
      assembly: length_filter/filtered_contigs_fasta
      virfinder_tsv: virfinder/virfinder_output
      virsorter_fastas: virsorter/virsorter_fastas
      pprmeta_csv: pprmeta/pprmeta_output
    out:
      - high_confidence_contigs
      - low_confidence_contigs
      - prophages_contigs

  # Restore names
  restore_contig_names:
    label: Restore contig names
    run: ./Tools/FastaRename/fasta_restore_swf.cwl
    in:
      contigs: length_filter/filtered_contigs_fasta
      high_confidence_contigs: parse_pred_contigs/high_confidence_contigs
      low_confidence_contigs: parse_pred_contigs/low_confidence_contigs
      prophages_contigs: parse_pred_contigs/prophages_contigs
      name_map: fasta_rename/name_map
    out:
      - contigs_resnames
      - high_confidence_contigs_resnames
      - low_confidence_contigs_resnames
      - prophages_contigs_resnames

  prodigal:
    label: Prodigal
    run: ./Tools/Prodigal/prodigal_swf.cwl
    in:
      high_confidence_contigs: restore_contig_names/high_confidence_contigs_resnames
      low_confidence_contigs: restore_contig_names/low_confidence_contigs_resnames
      prophages_contigs: restore_contig_names/prophages_contigs_resnames
    out:
      - high_confidence_contigs_genes
      - low_confidence_contigs_genes
      - prophages_contigs_genes

  hmmscan:
    label: hmmscan
    run: ./Tools/HMMScan/hmmscan_swf.cwl
    in:
      output_name:
        source: input_fasta_file
        valueFrom: $(self.nameroot)
      aa_fasta_files:
        source: 
          - prodigal/high_confidence_contigs_genes
          - prodigal/low_confidence_contigs_genes
          - prodigal/prophages_contigs_genes
        linkMerge: merge_flattened
      hmmdb: hmmdb
      h3m: h3m
      h3i: h3i
      h3f: h3f
      h3p: h3p
    out:
      # single concatenated table
      - output_table

  ratio_evalue:
    label: ratio evalue ViPhOG
    run: ./Tools/RatioEvalue/ratio_evalue.cwl
    in:
      hmmscan_table: hmmscan/output_table
      hmms_tsv: add_hmms_tsv
    out:
      - informative_table

  annotation:
    label: ViPhOG annotations
    run: ./Tools/Annotation/viral_annotation_swf.cwl
    in:
      input_fastas:
        source:
          - prodigal/high_confidence_contigs_genes
          - prodigal/low_confidence_contigs_genes
          - prodigal/prophages_contigs_genes
        linkMerge: merge_flattened
      hmmer_table: ratio_evalue/informative_table
    out:
      - annotation_tables

  assign:
    label: Taxonomic assign
    run: ./Tools/Assign/assign_swf.cwl
    in:
      input_tables: annotation/annotation_tables
      ncbi_tax_db: ncbi_tax_db_file
    out:
      - assign_tables

  krona:
    label: krona plots
    run: ./Tools/Krona/krona_swf.cwl
    in:
      assign_tables: assign/assign_tables
      combined_output_name:
        source: input_fasta_file
        valueFrom: $(self.nameroot)_combined_taxonomy_counts.tsv
    out:
      - krona_tables
      - krona_htmls
      - krona_combined_table
      - krona_combined_html

  imgvr_blast:
    label: Blast in a database of viral sequences including metagenomes
    run: ./Tools/IMGvrBlast/imgvr_blast_swf.cwl
    in:
      fasta_files:
        source:
          - restore_contig_names/high_confidence_contigs_resnames
          - restore_contig_names/low_confidence_contigs_resnames
          - restore_contig_names/prophages_contigs_resnames
        linkMerge: merge_flattened
      database: img_blast_database_dir
    out:
       - merged_tsvs
  
  mashmap:
    label: MashMap
    run: ./Tools/MashMap/mashmap_swf.cwl
    requirements:
        ResourceRequirement:
          coresMin: 4
          ramMin: 3814
    when: $(inputs.reference !== undefined && inputs.reference !== null)
    in:
      input_fastas:
        source:
          - restore_contig_names/high_confidence_contigs_resnames
          - restore_contig_names/low_confidence_contigs_resnames
          - restore_contig_names/prophages_contigs_resnames
        linkMerge: merge_flattened
      reference: mashmap_reference_file
    out:
      # each table will have the input as prefix of the name
      - output_table
  
  # Rename virsorter, virfinder and pprmeta results
  restore_tools_outputs_names:
    label: Restore contig names on ppmeta,virsorter and virfinder results
    doc: |
      virsorter, virfinder and pprmeta are fed
      a fasta file with renamed contigs, due problem with 
      how those tools handle fasta files.
      This step restores the contigs within the results
    run: ./Tools/RestoreOutputNames/restore_tools_outputs_swf.cwl
    in:
      virsorter_results: virsorter/virsorter_fastas
      pprmeta_results: pprmeta/pprmeta_output
      virfinder_results: virfinder/virfinder_output
      name_map: fasta_rename/name_map
    out:
      - virsorter_results_restored
      - pprmeta_results_restored
      - virfinder_results_restored

  checkv:
    label: CheckV
    run: ./Tools/checkv/checkv_swf.cwl
    requirements:
        ResourceRequirement:
          coresMin: 4
          ramMin: 3814
    in:
      input_fastas:
        source:
          - restore_contig_names/high_confidence_contigs_resnames
          - restore_contig_names/low_confidence_contigs_resnames
          - restore_contig_names/prophages_contigs_resnames
        linkMerge: merge_flattened
      database: checkv_database
    out:
      - quality_summary_tables
      - completeness_tables
      - contamination_tables

outputs:
  filtered_contigs:
    outputSource: restore_contig_names/contigs_resnames
    type: File
  # intermediary files
  virsorter_output_fastas:
    outputSource: restore_tools_outputs_names/virsorter_results_restored
    type: File[]
  pprmeta_file:
    outputSource: restore_tools_outputs_names/pprmeta_results_restored
    type: File
  virfinder_output:
    outputSource: restore_tools_outputs_names/virfinder_results_restored
    type: File
  ratio_evalue_output:
    outputSource: ratio_evalue/informative_table
    type: File
  # fully analized files
  high_confidence_contigs:
    outputSource: restore_contig_names/high_confidence_contigs_resnames
    type: File?
  low_confidence_contigs:
    outputSource: restore_contig_names/low_confidence_contigs_resnames
    type: File?
  parse_prophages_contigs:
    outputSource: restore_contig_names/prophages_contigs_resnames
    type: File?
  high_confidence_faa:
    outputSource: prodigal/high_confidence_contigs_genes
    type: File?
  low_confidence_faa:
    outputSource: prodigal/low_confidence_contigs_genes
    type: File?
  prophages_faa:
    outputSource: prodigal/prophages_contigs_genes
    type: File?
  ViPhOG_annotations:
    outputSource: annotation/annotation_tables
    type:
      type: array
      items: File
  taxonomy_assignations:
    outputSource: assign/assign_tables
    type:
      type: array
      items: File
  krona_tables:
    outputSource: krona/krona_tables
    type:
      type: array
      items: File
  krona_plots:
    outputSource: krona/krona_htmls
    type:
      type: array
      items: File
  krona_table_all:
    outputSource: krona/krona_combined_table
    type: File
  krona_plot_all:
    outputSource: krona/krona_combined_html
    type: File
  hmmscan_results:
    outputSource: hmmscan/output_table
    type: File
  blast_merged_tsvs:
    outputSource: imgvr_blast/merged_tsvs
    type: File[]
  # CheckV
  quality_summary_tables:
    outputSource: checkv/quality_summary_tables
    type: File[]
  completeness_tables:
    outputSource: checkv/completeness_tables
    type: File[]
  contamination_tables:
    outputSource: checkv/contamination_tables
    type: File[]
  # optional 
  mashmap_hits:
    outputSource: mashmap/output_table
    type:
      - "null"
      - type: array
        items: File

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"