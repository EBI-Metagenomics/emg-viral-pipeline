#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: CheckV

doc: CheckV sub-worklow

requirements:
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  input_fastas:
    type:
      type: array
      items: ["null", "File"]
    format: edam:format_1929
    doc: FASTA files
  database:
    type: Directory
    doc: |
      CheckV database (https://portal.nersc.gov/CheckV/checkv-db-v1.0.tar.gz)

steps:
  checkv:
    run: checkv.cwl
    scatter: query
    label: checkv
    when: $(inputs.query !== null && inputs.query.nameroot && !inputs.query.nameroot.includes('empty_'))
    in:
      query: input_fastas
      database: database
    out:
      - quality_summary_table
      - completeness_table
      - contamination_table

outputs:
  quality_summary_tables:
    type: File[]
    outputSource:
      - checkv/quality_summary_table
    pickValue: all_non_null
  completeness_tables:
    type: File[]
    outputSource:
      - checkv/completeness_table
    pickValue: all_non_null
  contamination_tables:
    type: File[]
    outputSource:
      - checkv/contamination_table
    pickValue: all_non_null


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