#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Viral contig annotation"

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/viral_contigs_annotation.py

baseCommand: ["python", "viral_contigs_annotation.py"]

arguments: ["-o", $(runtime.outdir)]

inputs:
  input_fasta:
    type: File?
    format: edam:format_1929
    inputBinding:
      separate: true
      prefix: "-p"
  input_table:
    type: File
    format: edam:format_3475
    inputBinding:
      separate: true
      prefix: "-t"

outputs:
  annotation_table:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*_annotation.tsv"

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