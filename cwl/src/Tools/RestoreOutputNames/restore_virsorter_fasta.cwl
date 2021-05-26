#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Fasta rename utility"

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: ../../../../bin/restore_virsorter_fastas.py

doc: |
  Python script to rename VirSorter results fasta,
  reversing the changes of fasta_rename in virify.

baseCommand: ["python", "restore_virsorter_fastas.py"]

inputs:
  input:
    type: File
    format: edam:format_1929
    inputBinding:
      prefix: "--input"
  name_map:
    type: File
    inputBinding:
      prefix: "--map"

arguments:
  - prefix: "--output"
    valueFrom: |
      ${
        if (inputs.input && inputs.input.nameroot) {
          return inputs.input.nameroot + ".fasta";
        } else {
          return "empty_map.tsv";
        }
      }

outputs:
  restored_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: "*.fasta"

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