#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Prodigal

doc: Protein-coding gene prediction for prokaryotic genomes

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/prodigal:v2.6.3"
  SoftwareRequirement:
    packages:
      prodigal:
        specs: [ "https://github.com/hyattpd/Prodigal" ]
        version: [ "2.6.3" ]

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: ../../../../bin/prodigal_wrapper.sh 

baseCommand: ["bash", "prodigal_wrapper.sh"]

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
          return inputs.input_fasta.nameroot + "_predicted_cds.faa";
        } else {
          return "empty_predicted_cds.faa";
        }
      }
    position: 3

outputs:
  output_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: "*.faa"

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