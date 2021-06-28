#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Convert the assing taxonomy table

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/generate_counts_table.py

baseCommand: ["python", "generate_counts_table.py"]

inputs:
  assign_table:
    type: File
    format: edam:format_3475
    label: Tab-delimited text file
    inputBinding:
      prefix: "-f"

arguments:
  - "-o"
  - $(inputs.assign_table.nameroot)_counts.tsv

outputs:
  count_table:
    type: File
    format: edam:format_3475    
    outputBinding:
      glob: "*_counts.tsv"

$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"