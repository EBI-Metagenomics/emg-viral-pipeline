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
  mgyp_mapping:
    type: File?
    format: edam:format_3475

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
    when: $(mgyp_mapping)
    run: ../utils/assign_mgyps.cwl
    in:
      high_confidence_contigs_cds: high_confidence_prodigal/output_fasta
      low_confidence_contigs_cds: low_confidence_prodigal/output_fasta
      prophages_contigs_cds: prophages_prodigal/output_fasta
      mgyp_mapping: mgyp_mapping
    out:
      - high_confidence_contigs_cds_mgyps
      - low_confidence_contigs_cds_mgyps
      - prophages_contigs_cds_mgyps

outputs:
  high_confidence_contigs_cds:
    outputSource: 
      - assign_mgyp/high_confidence_contigs_cds_mgyps
      - high_confidence_prodigal/output_fasta
    pickValue: first_non_null
    type: File?
    format: edam:format_1929
  low_confidence_contigs_cds:
    outputSource: 
      - assign_mgyp/low_confidence_contigs_cds_mgyps
      - low_confidence_prodigal/output_fasta
    pickValue: first_non_null
    type: File?
    format: edam:format_1929
  prophages_contigs_cds:
    outputSource: 
      - assign_mgyp/prophages_contigs_cds_mgyps
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