#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "cat an array of files"

requirements:
  InlineJavascriptRequirement: {}  # to propagate the file format

inputs:
  name:
    type: string
  files:
    type: File[]
    streamable: true
    inputBinding:
      position: 1

baseCommand: ["cat"]

stdout: result

outputs:
  result:
    type: File
    outputBinding:
      glob: result
      outputEval: |
        ${ self[0].basename = inputs.name; 
           return self; }

$namespaces:
 s: http://schema.org/
$schemas:
 - https://schema.org/version/latest/schema.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"