#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: VirFinder

hints:
 DockerRequirement:
   dockerFile: Dockerfile

baseCommand: ["run_virfinder.Rscript"]

inputs:
  model:
    type: File
    format: edam:format_2330
    inputBinding:
      separate: true
      position: 0
  fasta_file:
    type: File
    format: edam:format_1929
    inputBinding:
      separate: true
      position: 1

arguments:
  - valueFrom: $(runtime.outdir)
    position: 2
  
stdout: stdout.txt
stderr: stderr.txt

outputs:
  virfinder_output:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "*_virfinder_all.tsv"

doc: |
  VirFinder is a method for finding viral contigs from de novo assemblies.
  usage: Rscript run_virfinder.Rscript <model.rda> <input.fasta> <output.tsv>


$namespaces:
 s: http://schema.org/
 edam: http://edamontology.org/
$schemas:
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"