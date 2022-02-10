#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: merge blast with IMG/VR db

doc: Combine the filtered blast results with meta information from the IMG/VR database.

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/imgvr_merge.py

baseCommand: ["python", "imgvr_merge.py"]

inputs:
  blast_results_filtered:
    type: File
    format: edam:format_3475
    inputBinding:
      prefix: "-f"
  database:
    type: Directory
    inputBinding:
      prefix: "-d"
      valueFrom:
        $(self.path)/IMGVR_all_Sequence_information.tsv
  outfile:
    type: string
    inputBinding:
      prefix: "-o"

outputs:
  merged_tsv:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*.tsv"

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