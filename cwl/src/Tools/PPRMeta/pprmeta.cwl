#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "PPR-Meta"

baseCommand: [ "bash", "pprmeta.sh"]

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/pprmeta:v1.1"

inputs:
  fasta_file:
    type: File
    label: contigs
    format: edam:format_1929
    inputBinding:
      prefix: "-f"

arguments:
  - "-o"
  - $(runtime.outdir)/$(inputs.fasta_file.nameroot)_pprmeta.csv

outputs:
  pprmeta_output:
    type: File
    format: edam:format_3752
    outputBinding:
      glob: "*.csv"

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