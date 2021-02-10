#!/usr/bin/env cwl-runner
cwlVersion: v1.2.0
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
    type: File?
    doc: |
      PPR-Meta singularity simg file
  use_mgyp_from_assembly_pipeline: 
    type: boolean  
    default: false  # flag to rename Prodigal prediction headers to MGYPs
  mapfile_from_assembly_pipeline: File?
    

steps:
  fasta_rename:
    label: Rename contigs
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
    label: Combine
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
      high_confidence_contigs: parse_pred_contigs/high_confidence_contigs
      low_confidence_contigs: parse_pred_contigs/low_confidence_contigs
      prophages_contigs: parse_pred_contigs/prophages_contigs
      name_map: fasta_rename/name_map
    out:
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
      use_mgyp_from_assembly_pipeline: use_mgyp_from_assembly_pipeline
      mapfile_from_assembly_pipeline: mapfile_from_assembly_pipeline
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
      - blast_results
      - blast_result_filtered
      - merged_tsvs
  
  mashmap:
    label: MashMap
    run: ./Tools/MashMap/mashmap_swf.cwl
    requirements:
        ResourceRequirement:    # overrides the ResourceRequirements in first-step.cwl
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
  
outputs:
  filtered_contigs:
    outputSource: length_filter/filtered_contigs_fasta
    type: File
  virfinder_output:
    outputSource: virfinder/virfinder_output
    type: File
  virsorter_output_fastas:
    outputSource: virsorter/virsorter_fastas
    type: File[]
  pprmeta_file:
    outputSource: pprmeta/pprmeta_output
    type: File
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
  blast_result_filtered:
    outputSource: imgvr_blast/blast_result_filtered
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
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"