#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Prodigal

doc: Protein-coding gene prediction for prokaryotic genomes

hints:
 DockerRequirement:
   dockerFile: Dockerfile 

requirements:
  InlineJavascriptRequirement: {}

baseCommand: ["prodigal_wrapper.sh"]

inputs:
  input_fasta:
    type: File?
    format: edam:format_1929
    inputBinding:
      separate: true
      prefix: "-i"
      position: 1 # needed for wrapper

arguments:
  - prefix: -p
    valueFrom: "meta"
    position: 2
  - prefix: -a
    valueFrom: |
      ${
        if (inputs.input_fasta && inputs.input_fasta.nameroot) {
          return inputs.input_fasta.nameroot + "_prodigal.faa";
        } else {
          return "empty_prodigal.faa";
        }
      }
    position: 3

stdout: stdout.txt
stderr: stderr.txt

outputs:
  stdout: stdout
  stderr: stderr
  output_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: "*_prodigal.faa"

$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"