#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: Restore contig names

requirements:
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  virsorter_results:
    type: File[]
    format: edam:format_1929
  pprmeta_results:
    type: File
    format: edam:format_3752
  virfinder_results:
    type: File
    format: edam:format_3475
  name_map:
    type: File
    format: edam:format_3475

steps:
  restore_virsorter_results:
    label: Restore filtered contigs names
    run: restore_virsorter_fasta.cwl
    scatter: input
    in:
      input: virsorter_results
      name_map: name_map
    out:
      - restored_fasta  
  restore_pprmeta:
    label: Restore contig names in ppprmeta
    run: table_rename.cwl
    in:
      input: pprmeta_results
      output:
        source: pprmeta_results
        valueFrom: $(self.basename)
      map_file: name_map
    out:
      - modified_table
  virfinder_results:
    label: Restore contig names in virfinder
    run: table_rename.cwl
    in:
      input: virfinder_results
      map_file: name_map
      output:
        source: virfinder_results
        valueFrom: $(self.basename)
    out:
      - modified_table

outputs:
  virsorter_results_restored:
    type: File[]
    format: edam:format_1929
    outputSource: restore_virsorter_results/restored_fasta
  pprmeta_results_restored:
    type: File
    format: edam:format_3475
    outputSource: restore_pprmeta/modified_table
  virfinder_results_restored:
    type: File
    format: edam:format_3752
    outputSource: virfinder_results/modified_table

doc: |
  Restore the contig names using the map file in ppmeta, virfinder and virsorter output files.

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