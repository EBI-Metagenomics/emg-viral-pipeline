#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: Restore contig names

inputs:
  contigs:
    type: File
    format: edam:format_1929
  high_confidence_contigs:
    type: File?
    format: edam:format_1929
  low_confidence_contigs:
    type: File?
    format: edam:format_1929
  prophages_contigs:
    type: File?
    format: edam:format_1929  
  name_map:
    type: File
    format: edam:format_3475

steps:
  rename_contigs:
    label: Restore filtered contigs names
    run: fasta_restore.cwl
    in:
      input: contigs
      name_map: name_map
    out:
      - restored_fasta  
  rename_hc:
    label: Restore high conf.
    run: fasta_restore.cwl
    in:
      input: high_confidence_contigs
      name_map: name_map
    out:
      - restored_fasta
  rename_lc:
    label: Restore low conf.
    run: fasta_restore.cwl
    in:
      input: low_confidence_contigs
      name_map: name_map
    out:
      - restored_fasta
  rename_p:
    label: Restore prophages
    run: fasta_restore.cwl
    in:
      input: prophages_contigs
      name_map: name_map
    out:
      - restored_fasta      

outputs:
  contigs_resnames:
    type: File
    format: edam:format_1929
    outputSource: rename_contigs/restored_fasta
  high_confidence_contigs_resnames:
    type: File?
    format: edam:format_1929
    outputSource: rename_hc/restored_fasta
  low_confidence_contigs_resnames:
    type: File?
    format: edam:format_1929
    outputSource: rename_lc/restored_fasta
  prophages_contigs_resnames:
    type: File?
    format: edam:format_1929
    outputSource: rename_p/restored_fasta

doc: Restore the contig names using the map file

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