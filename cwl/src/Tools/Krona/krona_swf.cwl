#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: Krona

requirements:
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  combined_output_name:
    type: string
  assign_tables:
    type: File[]
    format: edam:format_3475
    label: tsv tables

steps:
  convert_table:
    run: generate_counts_table.cwl
    label: Convert table for Krona
    scatter: assign_table
    in:
      assign_table: assign_tables
    out:
      - count_table  
  krona_individual:
    run: krona.cwl
    label: ktImportText
    scatter: otu_counts
    in:
      otu_counts: convert_table/count_table
    out:
      - krona_html
  concatenate:
    run: ../Utils/concatenate.cwl
    label: CAT the tables
    in:
      files: convert_table/count_table
      name: combined_output_name
    out:
      - result
  krona_combined:
    run: krona.cwl
    label: ktImportText
    in:
      otu_counts: concatenate/result
    out:
      - krona_html

outputs:
  krona_htmls:
    outputSource: krona_individual/krona_html
    format: edam:format_2331
    type: File[]
  krona_tables:
    outputSource: convert_table/count_table
    format: edam:format_3475
    type: File[]
  krona_combined_html:
    outputSource: krona_combined/krona_html
    format: edam:format_2331
    type: File
  krona_combined_table:
    outputSource: concatenate/result
    type: File

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