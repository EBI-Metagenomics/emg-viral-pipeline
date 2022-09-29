#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Fasta rename utility"

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/rename_fasta.py

doc: |
  Small python script to rename a multi-fasta sequences, it's also possible to
  restore the names using the generated map file.
  In order to restore the multi-fasta use fasta_name_restore.cwl.

baseCommand: ["python", "rename_fasta.py"]

inputs:
  input:
    type: File
    format: edam:format_1929
    inputBinding:
      prefix: "--input"

arguments:
  - prefix: "--output"
    valueFrom: |
      ${
        if (inputs.input && inputs.input.nameroot) {
          return inputs.input.nameroot + "_renamed.fasta";
        } else {
          return "empty_map.tsv";
        }
      }
  - prefix: "--map"
    valueFrom: |
      ${
        if (inputs.input && inputs.input.nameroot) {
          return inputs.input.nameroot + "_map.tsv";
        } else {
          return "empty_renamed.fasta";
        }
      }
  - valueFrom: "rename"
    position: 3

outputs:
  renamed_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: "*.fasta"
  name_map:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*.tsv"

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