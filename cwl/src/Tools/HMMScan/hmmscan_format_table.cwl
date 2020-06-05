#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "hmmscan table format"

doc: |
  Format the hmmscan table results table.

  Usage: hmmscan_format_table.py -t input_table.tsv -o output_name

baseCommand: ["hmmscan_format_table.py"]

inputs:
  input_table:
    type: File
    inputBinding:
      prefix: "-t"
  output_name:
    type: string
    inputBinding:
      prefix: "-o"

stdout: stdout.txt
stderr: stderr.txt

outputs:
  output_table:
    type: File
    outputBinding:
      glob: $(inputs.output_name).tsv

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