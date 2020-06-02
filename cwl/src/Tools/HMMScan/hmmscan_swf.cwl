#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

label: Hmmscan

doc: |
  Run hmmscan over an array of files (supports empty or non existent files).
  The output will be the concatenation of the output tables.

requirements:
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  aa_fasta_files:
    type:
      type: array
      items: ["null", "File"]
    doc: FASTA Protein files
  database:
    type: Directory

steps:
  hmmscan:
    run: hmmscan.cwl
    scatter: aa_fasta_file
    label: Run hmmscan
    in:
      aa_fasta_file: aa_fasta_files
      database: database
    out:
      - output_table
  concatenate:
    run: ../Utils/concatenate.cwl
    label: CAT the tables
    in:
      files: hmmscan/output_table
      name:
        valueFrom: "tmp_table.tsv"
    out:
      - result
  format_table:
    run: hmmscan_format_table.cwl
    label: Format the table
    in:
      input_table: concatenate/result
      output_name:
        valueFrom: "hmmer_table"
    out:
      - output_table

outputs:
  output_table:
    type: File
    outputSource: format_table/output_table

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"