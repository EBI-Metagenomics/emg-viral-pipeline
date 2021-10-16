#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

doc: CheckV

label: CheckV

requirements:
  InlineJavascriptRequirement: {}

hints:
  # TODO: tag the version
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/checkv"

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
          self[0].basename = inputs.query.nameroot + "_quality_summary.tsv";
          return self;
        }
    doc: |
        This contains integrated results from the three main modules and should be the main output referred to. Below is an example to demonstrate the type of results you can expect in your data, space-delimited with each line consisting of 
        "contig_id	contig_length	genome_copies	gene_count	viral_genes	host_genes	checkv_quality	miuvig_quality	completeness	completeness_method	contamination	provirus	termini	warnings"
        https://bitbucket.org/berkeleylab/checkv/src/master/

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