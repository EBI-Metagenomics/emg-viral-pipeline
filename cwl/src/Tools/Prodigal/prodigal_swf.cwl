#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: Prodigal SWF

doc: |
  SubWorkflow for prodigal.
  Protein-coding gene prediction for prokaryotic genomes.

requirements:
  InlineJavascriptRequirement: {}

inputs:
  high_confidence_contigs:
    type: File?
    format: edam:format_1929
  low_confidence_contigs:
    type: File?
    format: edam:format_1929
  prophages_contigs:
    type: File?
    format: edam:format_1929
  use_mgyp_from_assembly_pipeline: boolean
  mapfile_from_assembly_pipeline: File?

steps:
  high_confidence_prodigal:
    run: prodigal.cwl
    in:
      input_fasta: high_confidence_contigs
    out:
      - output_fasta
  low_confidence_prodigal:
    run: prodigal.cwl
    in:
      input_fasta: low_confidence_contigs
    out:
      - output_fasta
  prophages_prodigal:
    run: prodigal.cwl
    in:
      input_fasta: prophages_contigs
    out:
      - output_fasta

  assign_mgyp:
    label: Assign MGYPs to annotated proteins
    when: $(inputs.condition_flag)
    run: ../FastaRename/fasta_restore_swf.cwl
    in:
      condition_flag: use_mgyp_from_assembly_pipeline
      high_confidence_contigs: high_confidence_prodigal/output_fasta
      low_confidence_contigs: low_confidence_prodigal/output_fasta
      prophages_contigs: prophages_prodigal/output_fasta
      name_map: mapfile_from_assembly_pipeline
      proteins_rename_flag: { default: true }
    out:
      - high_confidence_contigs_resnames
      - low_confidence_contigs_resnames
      - prophages_contigs_resnames


outputs:
  high_confidence_contigs_genes:
    outputSource: 
      - assign_mgyp/high_confidence_contigs_resnames
      - high_confidence_prodigal/output_fasta
      pickValue: first_non_null
    type: File?
    format: edam:format_1929
  low_confidence_contigs_genes:
    outputSource: 
      - assign_mgyp/low_confidence_contigs_resnames
      - low_confidence_prodigal/output_fasta
      pickValue: first_non_null
    type: File?
    format: edam:format_1929
  prophages_contigs_genes:
    outputSource: 
      - assign_mgyp/prophages_contigs_resnames
      - prophages_prodigal/output_fasta
      pickValue: first_non_null
    type: File?
    format: edam:format_1929

$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"