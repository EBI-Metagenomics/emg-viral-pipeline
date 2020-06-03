#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: VirFinder

hints:
 DockerRequirement:
   dockerFile: Dockerfile

requirements:
  InlineJavascriptRequirement: {}

baseCommand: ["run_virfinder.Rscript"]

inputs:
  fasta_file:
    type: File
    format: edam:format_1929
    inputBinding:
      separate: true
      position: 0

arguments:
  - valueFrom: virfinder_output.tsv
    position: 2

stdout: stdout.txt
stderr: stderr.txt

outputs:
  virfinder_output:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: virfinder_output.tsv

doc: |
  VirFinder is a method for finding viral contigs from de novo assemblies.
  usage: Rscript run_virfinder.Rscript <input.fasta> <output.tsv>


$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"