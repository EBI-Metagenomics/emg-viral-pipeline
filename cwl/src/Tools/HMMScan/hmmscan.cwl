#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: hmmscan wrapper

hints:
 DockerRequirement:
   dockerPull: "docker.io/microbiomeinformatics/hmmer:v3.1b2"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.hmmdb)
      - $(inputs.h3m)
      - $(inputs.h3i)
      - $(inputs.h3f)
      - $(inputs.h3p)

baseCommand: ["hmmscan_wrapper.sh"]

inputs:
  hmmdb:
    type: File
    inputBinding:
      position: 4
      valueFrom: $(self.basename)
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
  aa_fasta_file:
    type: File
    format: edam:format_1929
    inputBinding:
      position: 5
      separate: true

arguments:
  - prefix: -E
    valueFrom: "0.001"
    position: 2
  - prefix: --domtblout
    valueFrom: $(inputs.aa_fasta_file.nameroot)_hmmscan.tbl
    position: 3
  - valueFrom: --noali
    position: 1
  - prefix: --cpu
    valueFrom: $(runtime.cores)
    position: 2

outputs:
  output_table:
    type: File
    outputBinding:
      glob: "*hmmscan.tbl"

doc: Biosequence analysis using profile hidden Markov models

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