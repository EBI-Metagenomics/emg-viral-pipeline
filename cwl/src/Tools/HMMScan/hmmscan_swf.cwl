#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

label: Hmmscan

doc: |
  Run hmmscan over an array of files (supports empty or non existent files).
  Each file will be chunked in 1000 sequences per file to improve the performance.
  The output will be the concatenation of the output tables.

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  aa_fasta_files:
    type:
      type: array
      items: ["null", "File"]
    doc: FASTA Protein files
  database:
    type: Directory

steps:
  chunk_fasta:
    run: ../Utils/fasta_chunker.cwl
    scatter: fasta_file
    in:
      fasta_file: aa_fasta_files
    out:
      - fasta_chunks

  hmmscan_swf:
    scatter: fasta_files
    in: 
      fasta_files: chunk_fasta/fasta_chunks
      database: database
    out:
      - output_files
    run:
      class: Workflow
      requirements: 
        ScatterFeatureRequirement: {}
        ResourceRequirement:
          coresMin: 4
          ramMin: 6000
      inputs:
        fasta_files:
          type:
            type: array
            items: "File"
        database:
          type: Directory
      steps:
        hmmscan:
          run: hmmscan.cwl
          label: hmmscan
          scatter: aa_fasta_file
          in:
            aa_fasta_file: fasta_files
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
      outputs:
        output_files:
          type: File
          outputSource: concatenate/result

  concatenate:
    run: ../Utils/concatenate.cwl
    label: CAT the tables
    in:
      files: hmmscan_swf/output_files
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
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"