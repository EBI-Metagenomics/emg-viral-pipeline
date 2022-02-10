#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: blast against IMG/VR

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/blast:v2.9.0"

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: $(inputs.number_of_cpus)
    ramMin: 9536
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: ../../../../bin/imgvr_blast.sh

baseCommand: ["bash", "imgvr_blast.sh"]

inputs:
  database:
    type: Directory
    inputBinding:
      prefix: "-d"
  query:
    type: File?
    format: edam:format_1929 
    inputBinding:
      prefix: "-q"
  number_of_cpus:
    type: int?
    default: 12
    inputBinding:
      separate: true
      prefix: "-c"

arguments: 
  - prefix: "-o"
    valueFrom: |
      ${
        if (inputs.query && inputs.query.nameroot) {
          return inputs.query.nameroot + "_imgvr_blast";
        } else {
          return "empty_imgvr_blast";
        }
      }

outputs:
  blast_result:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: $("*_imgvr_blast.tsv")
  blast_result_filtered:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: $("*_imgvr_blast_filtered.tsv")

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