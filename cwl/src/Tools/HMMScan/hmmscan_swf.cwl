#!/usr/bin/env cwl-runner
cwlVersion: v1.2
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
  output_name:
    type: string
  aa_fasta_files:
    type:
      type: array
      items: ["null", "File"]
    doc: FASTA Protein files
  hmmdb:
    type: File
    doc: |
      HMMScan Viral HMM (databases/vpHMM/vpHMM_database.hmm).
  h3m:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3m)
  h3i:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3i)
  h3f:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3f)
  h3p:
    type: File
    doc: |
      HMM Database secondary file
      (databases/vpHMM/vpHMM_database.hmm.h3p)

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
      hmmdb: hmmdb
      h3m: h3m
      h3i: h3i
      h3f: h3f
      h3p: h3p
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
        hmmdb:
          type: File
          doc: HMM Database
        h3m:
          type: File
        h3i:
          type: File
        h3f:
          type: File
        h3p:
          type: File
      steps:
        hmmscan:
          run: hmmscan.cwl
          label: hmmscan
          scatter: aa_fasta_file
          in:
            aa_fasta_file: fasta_files
            hmmdb: hmmdb
            h3m: h3m
            h3i: h3i
            h3f: h3f
            h3p: h3p
          out:
            - output_table
        concatenate:
          run: ../Utils/concatenate.cwl
          label: CAT the tables
          in:
            files: hmmscan/output_table
            name:
              valueFrom: "inner_tmp_table.tsv"
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
      output_name: output_name
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
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"