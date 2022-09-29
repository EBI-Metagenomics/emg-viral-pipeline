#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: VirFinder

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/virfinder:v1.1__eb8032e"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/run_virfinder.Rscript

baseCommand: ["Rscript", "run_virfinder.Rscript"]

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
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - class: s:Organization
    s:name: "EMBL - European Bioinformatics Institute"
    s:url: "https://www.ebi.ac.uk"