#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: MashMap

doc: MashMap sub-worklow

requirements:
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  input_fastas:
    type:
      type: array
      items: ["null", "File"]
    format: edam:format_1929
    doc: FASTA files
  reference:
    type: File?

steps:
  mashmap:
    run: mashmap.cwl
    scatter: query
    label: run mashmap
    when: $(inputs.query !== null && inputs.query.nameroot && !inputs.query.nameroot.includes('empty_'))
    in:
      query: input_fastas
      reference: reference
      no_split:
        valueFrom: $(true)
      minimum_segment_length:
        valueFrom: $(2000)  
      output_file:
        valueFrom: |
            ${
                if (inputs.query && inputs.query.nameroot) {
                    return inputs.query.nameroot + "_mashmap.out";
                } else {
                    return "empty_mashmap.out";
                }
            }
    out:
      - mashmap_table

outputs:
  output_table:
    type: File[]
    outputSource:
      - mashmap/mashmap_table
    pickValue: all_non_null

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