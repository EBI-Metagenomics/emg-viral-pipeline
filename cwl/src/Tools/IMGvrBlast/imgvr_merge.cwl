#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: merge blast with IMG/VR db

requirements:
  InlineJavascriptRequirement: {}

doc: Combine the filtered blast results with meta information from the IMG/VR database.

baseCommand: ["imgvr_merge.py"]

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
        $(self.path + "/IMGVR_all_Sequence_information.tsv")
  outfile:
    type: string
    inputBinding:
      prefix: "-o"

stdout: stdout
stderr: stderr 

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
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"