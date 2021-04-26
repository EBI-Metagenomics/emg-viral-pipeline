#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: ViPhOG annotations

requirements:
  ScatterFeatureRequirement: {}

inputs:
  input_fastas:
    type:
      type: array
      items: ["File", "null"]
    doc: |
      FASTA Protein files
  hmmer_table:
    type: File
    doc: |
      HMMER concatenated tsv

steps:
  viral_annotation:
    run: viral_annotation.cwl
    scatter: input_fasta
    label: contigs annotation
    in:
      input_fasta: input_fastas
      input_table: hmmer_table
    out:
      - annotation_table

outputs:
  annotation_tables:
    outputSource: viral_annotation/annotation_table
    type: File[]

doc: |
  "Run viral_contigs_annotation.py on an array of files"

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