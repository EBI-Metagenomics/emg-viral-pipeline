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

outputs:
  high_confidence_contigs_genes:
    outputSource: high_confidence_prodigal/output_fasta
    type: File?
    format: edam:format_1929
  low_confidence_contigs_genes:
    outputSource: low_confidence_prodigal/output_fasta
    type: File?
    format: edam:format_1929
  prophages_contigs_genes:
    outputSource: prophages_prodigal/output_fasta
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