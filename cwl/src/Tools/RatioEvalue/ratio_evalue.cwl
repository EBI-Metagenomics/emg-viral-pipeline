#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Ratio Evalue table"

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/ratio_evalue_table.py

baseCommand: ["python", "ratio_evalue_table.py"]

arguments:
  - "-o"
  - $(inputs.hmmscan_table.nameroot)_informative.tsv

inputs:
  hmmscan_table:
    type: File
    inputBinding:
      separate: true
      prefix: "-i"
  hmms_tsv:
    type: File
    format: edam:format_3475
    inputBinding:
      separate: true
      prefix: "-t"
    doc: |
      tsv with the HMM

outputs:
  informative_table:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*informative.tsv"

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