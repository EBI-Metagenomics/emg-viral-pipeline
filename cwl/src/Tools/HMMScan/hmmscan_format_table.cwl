#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "hmmscan table format"

doc: |
  Format the hmmscan table results table.

  Usage: hmmscan_format_table.py -t input_table.tsv -o output_name

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: ../../../../bin/hmmscan_format_table.py

baseCommand: [ "python", "hmmscan_format_table.py" ]

inputs:
  input_table:
    type: File
    inputBinding:
      prefix: "-t"
  output_name:
    type: string
  
arguments:
  - "-o"
  - valueFrom: $(inputs.output_name)_hmmer

outputs:
  output_table:
    type: File
    outputBinding:
      glob: $(inputs.output_name)_hmmer.tsv

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