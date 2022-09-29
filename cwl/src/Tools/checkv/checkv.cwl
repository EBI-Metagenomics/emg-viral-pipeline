#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

doc: CheckV

label: CheckV

requirements:
  InlineJavascriptRequirement: {}

hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/checkv:v0.8.1"

baseCommand: ["checkv"]

inputs:

  query:
    type: File?
    format: edam:format_1929
    inputBinding:
      position: 2
    doc: |
      input query file fasta

  database:
    type: Directory
    inputBinding:
      prefix: "-d"
      position: 3
    doc: |
      CheckV checkv-db-v1.0 database

  threads:
    type: int?
    inputBinding:
      prefix: "-t"
      position: 4
      valueFrom: |
        ${
            if (self == null) {
                return runtime.cores;
            } else {
                return self;
            }
        }
    doc: |
      count of threads for parallel execution [default : 4]

arguments:
  - position: 1
    valueFrom: "end_to_end" 
  - position: 5
    valueFrom: $(runtime.outdir)

outputs:
  quality_summary_table:
    type: File
    format: edam:format_3751
    outputBinding:
      glob: "quality_summary.tsv"
      outputEval: |
        ${
          if (self && self.length > 0) {
            self[0].basename = inputs.query.nameroot + "_quality_summary.tsv";
            return self;
          } else {
            return self;
          }
        }
    doc: |
        This contains integrated results from the three main modules and should be the main output referred to.
        Below is an example to demonstrate the type of results you can expect in your data, space-delimited with each line consisting of 
        - contig_id
        - contig_length
        - genome_copies
        - gene_count
        - viral_genes
        - host_genes
        - checkv_quality
        - miuvig_quality
        - completeness
        - completeness_method
        - contamination 
        - provirus
        - termini
        - warnings
        https://bitbucket.org/berkeleylab/checkv/src/master/
  completeness_table:
    type: File
    format: edam:format_3751
    outputBinding:
      glob: "completeness.tsv"
      outputEval: |
        ${
          if (self && self.length > 0) {
            self[0].basename = inputs.query.nameroot + "_completeness.tsv";
            return self;
          } else {
            return self;
          }
        }
    doc: |
        Table with the following columns:
        - contig_id
        - contig_length
        - proviral_length 
        - aai_expected_length
        - aai_completeness
        - aai_confidence 
        - aai_error
        - aai_num_hits
        -	aai_top_hit
        - aai_id
        - aai_af
        - hmm_completeness_lower
        - hmm_hits
        For more information: https://bitbucket.org/berkeleylab/checkv/src/master/
  contamination_table:
    type: File
    format: edam:format_3751
    outputBinding:
      glob: "contamination.tsv"
      outputEval: |
        ${
          if (self && self.length > 0) {
            self[0].basename = inputs.query.nameroot + "_contamination.tsv";
            return self;
          } else {
            return self;
          }
        }
    doc: |
        Table with the following columns:
        - contig_id
        - contig_length
        - prediction_type
        - confidence_level
        - confidence_reason
        - repeat_length
        - repeat_count
        For more information: https://bitbucket.org/berkeleylab/checkv/src/master/

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