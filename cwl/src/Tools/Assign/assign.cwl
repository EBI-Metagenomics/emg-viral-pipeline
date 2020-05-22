#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "Viral contig assign"

hints:
 DockerRequirement:
   dockerFile: Dockerfile

requirements:
  InlineJavascriptRequirement: {}

baseCommand: 'contig_taxonomic_assign.py'

inputs:
  input_table:
    type: File
    inputBinding:
      separate: true
      prefix: "-i"
  ncbi_tax_db:
    type: File
    inputBinding:
      prefix: "-d"
    doc: |
      "ete3 NCBITaxa db https://github.com/etetoolkit/ete/blob/master/ete3/ncbi_taxonomy/ncbiquery.py
      http://etetoolkit.org/docs/latest/tutorial/tutorial_ncbitaxonomy.html
      This file was manually built and placed in the corresponding path (on databases)"

stdout: stdout.txt
stderr: stderr.txt

outputs:
  assign_table:
    type: File
    outputBinding:
      glob: "*tax_assign.tsv"

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"