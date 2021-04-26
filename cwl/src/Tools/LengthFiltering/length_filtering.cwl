#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Length Filter

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/filter_contigs_len.py

baseCommand: ["python", "filter_contigs_len.py"]

inputs:
  fasta_file:
    type: File
    format: edam:format_1929    
    inputBinding:
      separate: true
      prefix: "-f"
  length:
    type: float
    inputBinding:
      prefix: "-l"
  outdir:
    type: Directory?
    inputBinding:
      separate: true
      prefix: "-o"
  identifier:
    type: string?
    inputBinding:
      separate: true
      prefix: "-i"

outputs:
  filtered_contigs_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: "*_filt*.fasta"

doc: |
  usage: filter_contigs_len.py [-h] -f input_file -l length_thres -o output_dir -i sample_id

  Extract sequences at least X kb long.

  positional arguments:
    fasta              Path to fasta file to filter

  optional arguments:
    -h, --help         show this help message and exit
    -l LENGTH          Length threshold in kb of selected sequences (default: 5kb)
    -o OUTDIR          Relative or absolute path to directory where you want to store output (default: cwd)
    -i IDENT           Dataset identifier or accession number. Should only be introduced if you want to add it to each sequence header, along with a sequential number

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