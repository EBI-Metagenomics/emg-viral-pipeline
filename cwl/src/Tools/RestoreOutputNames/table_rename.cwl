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
        location: ../../../../bin/rename_table_column.py

doc: |
  Small python script to rename a tsv/csv file column with a mapping file.

baseCommand: ["python", "rename_table_column.py"]

inputs:
  input:
    type: File
    inputBinding:
      prefix: "--input"
  map_file:
    type: File
    inputBinding:
      prefix: "--map"
  output:
    type: string
    inputBinding:
      prefix: "--output"

outputs:
  modified_table:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: $(inputs.output)

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