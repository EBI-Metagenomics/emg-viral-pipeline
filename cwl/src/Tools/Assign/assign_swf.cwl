#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: "Viral contig assign"

requirements:
  ScatterFeatureRequirement: {}

inputs:
  input_tables:
    type: File[]
  ncbi_tax_db:
    type: File
    doc: |
      "ete3 NCBITaxa db https://github.com/etetoolkit/ete/blob/master/ete3/ncbi_taxonomy/ncbiquery.py
      http://etetoolkit.org/docs/latest/tutorial/tutorial_ncbitaxonomy.html
      This file was manually built and placed in the corresponding path (on databases)"

steps:
  viral_assignation:
    run: assign.cwl
    scatter: input_table
    in:
      input_table: input_tables
      ncbi_tax_db: ncbi_tax_db
    out:
      - assign_table

outputs:
  assign_tables:
    outputSource: viral_assignation/assign_table
    type: File[]

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