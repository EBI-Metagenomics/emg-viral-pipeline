#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "assign MGYPs"

hints:
  DockerRequirement:
    dockerPull: "microbiomeinformatics/emg-viral-pipeline-python3:v1"

requirements:
  InitialWorkDirRequirement:
    listing:
        - class: File
          location: ../../../../bin/assign_mgyps.py

baseCommand: ["python", "assign_mgyps.py"]

inputs:
  high_confidence_contigs_cds:
    type: File?
    format: edam:format_1929
    inputBinding:
      prefix: "-f"
  low_confidence_contigs_cds:
    type: File?
    format: edam:format_1929
    inputBinding:
      prefix: "-f"
  prophages_contigs_cds:
    type: File?
    format: edam:format_1929
    inputBinding:
      prefix: "-f"
  mgyp_mapping:
    type: File
    format: edam:format_3475
    inputBinding:
      prefix: "-m"

stderr: stderr
stdout: stdout

outputs:
  high_confidence_contigs_cds_mgyps:
    type: File?
    outputBinding:
      glob: "high_confidence*.faa"
  low_confidence_contigs_cds_mgyps:
    type: File?
    outputBinding:
      glob: "low_confidence*.faa"
  prophages_contigs_cds_mgyps:
    type: File?
    outputBinding:
      glob: "prophages*.faa"


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
