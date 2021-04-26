#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Parse predictions"

hints:
  DockerRequirement:
    dockerPull: "docker.io/microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/parse_viral_pred.py

baseCommand: ["python", "parse_viral_pred.py"]

inputs:
  assembly:
    type: File
    format: edam:format_1929
    inputBinding:
      separate: true
      prefix: "-a"
  virfinder_tsv:
    type: File?
    format: edam:format_3475
    inputBinding:
      separate: true
      prefix: "-f"
  virsorter_fastas:
    type: File[]
    format: edam:format_1929
    inputBinding:
      separate: true
      prefix: "-s"
  pprmeta_csv:
    type: File?
    format: edam:format_3752
    inputBinding:
      separate: true
      prefix: "-p"
  output_dir:
    type: string?
    inputBinding:
      separate: true
      prefix: "-o"

arguments:
  - "-r"

outputs:
  high_confidence_contigs:
    type: File?
    format: edam:format_1929
    outputBinding:
      glob: "*high_confidence_viral_contigs.fna"
  low_confidence_contigs:
    type: File?
    format: edam:format_1929
    outputBinding:
      glob: "*low_confidence_viral_contigs.fna"
  prophages_contigs:
    type: File?
    format: edam:format_1929
    outputBinding:
      glob: "*prophages.fna"

doc: |
  usage: parse_viral_pred.py [-h] -a ASSEMB -f FINDER -s SORTER [-o OUTDIR]

  description: script generates three output_files: high_confidence.fasta, low_confidence.fasta, Prophages.fasta

  optional arguments:
  -h, --help            show this help message and exit
  -a ASSEMB, --assemb ASSEMB
                        Metagenomic assembly fasta file
  -f FINDER, --vfout FINDER
                        Absolute or relative path to VirFinder output file
  -s SORTER, --vsdir SORTER
                        Absolute or relative path to directory containing
                        VirSorter output
  -o OUTDIR, --outdir OUTDIR
                        Absolute or relative path of directory where output
                        viral prediction files should be stored (default: cwd)
  -r, --prefix          Use the assembly filename as prefix for the outputs

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