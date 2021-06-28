#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: fasta chunker

doc: split FASTA by number of records

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: ../../../../bin/fasta_chunker.py

baseCommand: [ "python", "fasta_chunker.py" ]

inputs:
  fasta_file:
    type: File
    inputBinding:
      prefix: -i
    format: edam:format_1929
  chunk_size:
    type: int
    default: 1000
    inputBinding:
      prefix: -s
  file_format:
    type: string?
    inputBinding:
      prefix: -f

outputs:
  fasta_chunks:
    format: edam:format_1929 # FASTA
    type: File[]
    outputBinding:
      glob: "*_*.faa"

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