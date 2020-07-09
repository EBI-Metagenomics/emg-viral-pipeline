#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "Fasta name restore utility"

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/rename_fasta.py

doc: |
  Python script to restore the names on a multi-fasta using the name mapping file.
  In order to rename the multi-fasta use fasta_rename.cwl

baseCommand: ["python", "rename_fasta.py"]

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
    valueFrom: |
      ${
        if (inputs.input && inputs.input.nameroot) {
          return inputs.input.nameroot + "_restored.fasta";
        } else {
          return "empty_restored.fasta";
        }
      }
  - prefix: "--map"
    valueFrom: |
      ${
        if (inputs.input && inputs.input.nameroot) {
          return inputs.input.nameroot + "_map.tsv";
        } else {
          return "empty_map.tsv";
        }
      }
  - valueFrom: "restore"
    position: 3

outputs:
  restored_fasta:
    type: File?
    format: edam:format_1929
    outputBinding:
      glob: "*.fasta"
 
stdout: stdout.txt
stderr: stderr.txt

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"