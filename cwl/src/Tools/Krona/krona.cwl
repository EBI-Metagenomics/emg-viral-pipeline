#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Krona

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/krona:v2.7.1"

baseCommand: ["ktImportText"]

inputs:
  otu_counts:
    type: File
    label: Tab-delimited text file
    inputBinding:
      position: 2


arguments:
  - "-o"
  - $(inputs.otu_counts.nameroot)_krona.html

outputs:
  krona_html:
    type: File
    format: edam:format_2331
    outputBinding:
      glob: "*.html"

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