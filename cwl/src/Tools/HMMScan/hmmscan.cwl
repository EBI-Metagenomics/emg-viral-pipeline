#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: hmmscan wrapper

hints:
 DockerRequirement:
   dockerPull: "docker.io/microbiomeinformatics/hmmer:v3.1b2"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing: | 
      ${
        return inputs.database.listing;
      }

baseCommand: ["hmmscan_wrapper.sh"]

inputs:
  database:
    type: Directory
  aa_fasta_file:
    type: File
    format: edam:format_1929
    inputBinding:
      position: 5
      separate: true

arguments:
  - prefix: -E
    valueFrom: "0.001"
    position: 2
  - prefix: --domtblout
    valueFrom: $(inputs.aa_fasta_file.nameroot)_hmmscan.tbl
    position: 3
  - valueFrom: $(runtime.outdir)/vpHMM_database.hmm
    position: 4
  - valueFrom: --noali
    position: 1
  - prefix: --cpu
    valueFrom: $(runtime.cores)
    position: 2

# TODO: remove before production as HMMER is very verbose
stdout: hmmer_stdout.txt
stderr: hmmer_stderr.txt

outputs:
  output_table:
    type: File
    outputBinding:
      glob: "*hmmscan.tbl"

doc: Biosequence analysis using profile hidden Markov models

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"