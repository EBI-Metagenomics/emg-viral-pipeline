#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "Fasta name restore utility"

doc: |
  Python script to restore the names on a multi-fasta using the name mapping file.
  In order to rename the multi-fasta use fasta_rename.cwl

baseCommand: ["rename_fasta.py"]

inputs:
  input:
    type: File?
    format: edam:format_1929
    inputBinding:
      prefix: "--input"
  name_map:
    type: File
    inputBinding:
      prefix: "--map"

arguments:
  - prefix: "--output"
    valueFrom: "restored.fasta"
  - valueFrom: "restore"
    position: 3

outputs:
  restored_fasta:
    type: File?
    format: edam:format_1929
    outputBinding:
      glob: "restored.fasta"
 
stdout: stdout.txt
stderr: stderr.txt

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"