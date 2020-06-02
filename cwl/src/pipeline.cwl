#!/usr/bin/env cwl-runner
cwlVersion: v1.2.0-dev2
class: Workflow
label: virify

requirements:
  SubworkflowFeatureRequirement: {}  
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  input_fasta_file:  # input assembly
    type: File
    format: edam:format_1929
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
  add_hmms_tsv:
    type: File
    format: edam:format_3475
    doc: |
        Additonal metadata tsv
  hmmscan_database_dir:
    type: Directory
    doc: |
      HMMScan Viral HMM (databases/vpHMM/vpHMM_database).
      NOTE: it needs to be a full path.
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
  # optional steps
  mashmap_reference_file:
    type: File?
    doc: |
      MashMap Reference file. Use MashMap to 
  # == singularity containers == #
  pprmeta_simg:
    type: File
    doc: |
      PPR-Meta singularity simg file

steps:
  fasta_rename:
    label: Filter contigs
    run: ./Tools/FastaRename/fasta_rename.cwl
    in:
      input: input_fasta_file
    out:
      - renamed_fasta
      - name_map

  length_filter:
    label: Filter contigs
    run: ./Tools/LengthFiltering/length_filtering.cwl
    doc: Default lenght 1kb https://github.com/EBI-Metagenomics/emg-virify-scripts/issues/6
    in:
      fasta_file: fasta_rename/renamed_fasta
      length:
        default: 1.0
    out:
      - filtered_contigs_fasta

  virfinder:
    label: VirFinder
    run: ./Tools/VirFinder/virfinder.cwl
    in:
      fasta_file: length_filter/filtered_contigs_fasta
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
      - predicted_viral_seq_dir

  pprmeta:
    label: PPR-Meta
    run: ./Tools/PPRMeta/pprmeta.cwl
    in:
      singularity_image: pprmeta_simg
      fasta_file: length_filter/filtered_contigs_fasta
    out:
      - pprmeta_output

  parse_pred_contigs:
    label: Combine
    run: ./Tools/ParsingPredictions/parse_viral_pred.cwl
    in:
      assembly: length_filter/filtered_contigs_fasta
      virfinder_tsv: virfinder/virfinder_output
      virsorter_dir: virsorter/predicted_viral_seq_dir
      pprmeta_csv: pprmeta/pprmeta_output
    out:
      - high_confidence_contigs
      - low_confidence_contigs
      - prophages_contigs

  prodigal:
    label: Prodigal
    run: ./Tools/Prodigal/prodigal_swf.cwl
    in:
      high_confidence_contigs: parse_pred_contigs/high_confidence_contigs
      low_confidence_contigs: parse_pred_contigs/low_confidence_contigs
      prophages_contigs: parse_pred_contigs/prophages_contigs
    out:
      - high_confidence_contigs_genes
      - low_confidence_contigs_genes
      - prophages_contigs_genes

  hmmscan:
    label: hmmscan
    run: ./Tools/HMMScan/hmmscan_swf.cwl
    in:
      aa_fasta_files:
        source: 
          - prodigal/high_confidence_contigs_genes
          - prodigal/low_confidence_contigs_genes
          - prodigal/prophages_contigs_genes
        linkMerge: merge_flattened
      database: hmmscan_database_dir
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
    run:  ./Tools/Krona/krona_swf.cwl
    in:
      assign_tables: assign/assign_tables
    out:
      - krona_htmls
      - krona_all_html

  fasta_restore_name_hc:
    label: Restore fasta names
    run: ./Tools/FastaRename/fasta_restore.cwl
    in:
      input: parse_pred_contigs/high_confidence_contigs
      name_map: fasta_rename/name_map
    out:
      - restored_fasta

  fasta_restore_name_lc:
    label: Restore fasta names
    run: ./Tools/FastaRename/fasta_restore.cwl
    in:
      input: parse_pred_contigs/low_confidence_contigs
      name_map: fasta_rename/name_map
    out:
      - restored_fasta

  fasta_restore_name_pp:
    label: Restore fasta names
    run: ./Tools/FastaRename/fasta_restore.cwl
    in:
      input: parse_pred_contigs/prophages_contigs
      name_map: fasta_rename/name_map
    out:
      - restored_fasta

  imgvr_blast:
    label: Blast in a database of viral sequences including metagenomes
    run: ./Tools/IMGvrBlast/imgvr_blast_swf.cwl
    in:
      fasta_files:
        source:
          - parse_pred_contigs/high_confidence_contigs
          - parse_pred_contigs/low_confidence_contigs
          - parse_pred_contigs/prophages_contigs
        linkMerge: merge_flattened
      database: img_blast_database_dir
    out:
      - blast_results
      - blast_result_filtereds
      - merged_tsvs
  
  mashmap:
    label: MashMap
    run: ./Tools/MashMap/mashmap_swf.cwl
    when: $(inputs.mashmap_reference_file !== null)
    in:
      input_fastas:
        source:
          - parse_pred_contigs/high_confidence_contigs
          - parse_pred_contigs/low_confidence_contigs
          - parse_pred_contigs/prophages_contigs
        linkMerge: merge_flattened
      reference: mashmap_reference_file
    out:
      # each table will have the input as prefix of the name
      - output_table
  
outputs:
  filtered_contigs:
    outputSource: length_filter/filtered_contigs_fasta
    type: File
  virfinder_output:
    outputSource: virfinder/virfinder_output
    type: File
  virsorter_output:
    outputSource: virsorter/predicted_viral_seq_dir
    type: Directory
  high_confidence_contigs:
    outputSource: fasta_restore_name_hc/restored_fasta
    type: File?
  low_confidence_contigs:
    outputSource: fasta_restore_name_lc/restored_fasta
    type: File?
  parse_prophages_contigs:
    outputSource: fasta_restore_name_pp/restored_fasta
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
  taxonomy_assignations:
    outputSource: assign/assign_tables
    type:
      type: array
      items: File
  krona_plots:
    outputSource: krona/krona_htmls
    type:
      type: array
      items: File
  krona_plot_all:
    outputSource: krona/krona_all_html
    type: File
  blast_results:
    outputSource: imgvr_blast/blast_results
    type: File[]
  blast_result_filtereds:
    outputSource: imgvr_blast/blast_result_filtereds
    type: File[]
  blast_merged_tsvs:
    outputSource: imgvr_blast/merged_tsvs
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
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"