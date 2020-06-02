#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "Ratio Evalue table"

hints:
 DockerRequirement:
   dockerPull: Dockerfile

requirements:
  InlineJavascriptRequirement: {}

baseCommand: ["ratio_evalue_table.py"]

arguments:
  - "-o"
  - $( inputs.hmmscan_table.nameroot + "_informative.tsv" )

inputs:
  hmmscan_table:
    type: File
    inputBinding:
      separate: true
      prefix: "-i"
  hmms_tsv:
    type: File
    inputBinding:
      separate: true
      prefix: "-t"
    doc: |
      tsv with the HMM
outputs:
  stdout: stdout
  stderr: stderr
  informative_table:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*informative.tsv"

stdout: stdout.txt
stderr: stderr.txt

$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"