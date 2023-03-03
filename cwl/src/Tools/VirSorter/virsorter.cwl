#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: VirSorter

hints:
  ResourceRequirement:
    coresMin: $(inputs.number_of_cpus)
    ramMin: 9536
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/virsorter:1.0.6_edfeb8c5e72"

baseCommand: ["wrapper_phage_contigs_sorter_iPlant.pl"]

arguments:
  - "--db"
  - "2"

inputs:
  fasta_file:
    type: File
    format: edam:format_1929
    inputBinding:
      separate: true
      prefix: "-f"
  data_dir:
    type: Directory
    inputBinding:
      prefix: "--data-dir"
  dataset:
    type: string?
    inputBinding:
      separate: true
      prefix: "-d"
  custom_phage:
    type: string?
    inputBinding:
      separate: true
      prefix: "--cp"
  working_directory:
    type: string?
    inputBinding:
      separate: true
      prefix: "--wdir"
  number_of_cpus:
    type: int?
    default: 8
    inputBinding:
      separate: true
      prefix: "--ncpu"
  virome_decontamination_mode:
    type: boolean
    default: false
    inputBinding:
      separate: true
      prefix: "--virome"
    doc: |
      This is needed when providing VirSorter with an input file which is mostly (in your case entirely) viral. The reason is that VirSorter was initially designed for microbial single-cell genomes and metagenomes, i.e. in its default mode, VirSorter will first evaluate the different gene content features (i.e. % of viral genes, % of genes without PFAM affiliation, etc) on the whole dataset, and then look for contigs and or regions that are "more viral than average" (roughly). The "--virome" option bypasses this and forces the use of pre-computed features (based on microbial genomes from RefSeq).
  diamond:
    type: null?
    inputBinding:
      separate: true
      prefix: "--diamond"
  keep_db:
    type: null?
    inputBinding:
      separate: true
      prefix: "--keep-db"
  enrichment_statistics:
    type: null?
    inputBinding:
      separate: true
      prefix: "--no_c"

outputs:
  virsorter_fastas:
    type: File[]
    format: edam:format_1929
    outputBinding:
      glob: virsorter-out/Predicted_viral_sequences/*.fasta

  virsorter_genebanks:
    type: File[]
    outputBinding:
      glob: virsorter-out/Predicted_viral_sequences/*.gb
doc: |
  usage: wrapper_phage_contigs_sorter_iPlant.pl --fasta sequences.fa

  Required Arguments:

      -f|--fna       Fasta file of contigs

   Options:

      -d|--dataset   Code dataset (DEFAULT "VIRSorter")
      --cp           Custom phage sequence
      --db           Either "1" (DEFAULT Refseqdb) or "2" (Viromedb)
      --wdir         Working directory (DEFAULT cwd)
      --ncpu         Number of CPUs (default: 4)
      --virome       Add this flag to enable virome decontamination mode, for datasets
                     mostly viral to force the use of generic metrics instead of
                     calculated from the whole dataset. (default: off)
      --data-dir     Path to "virsorter-data" directory (e.g. /path/to/virsorter-data)
      --diamond      Use diamond (in "--more-sensitive" mode) instead of blastp.
                     Diamond is much faster than blastp and may be useful for adding
                     many custom phages, or for processing extremely large Fasta files.
                     Unless you specify --diamond, VirSorter will use blastp.
      --keep-db      Specifying this flag keeps the new HMM and BLAST databases created
                     after adding custom phages. This is useful if you have custom phages
                     that you want to be included in several different analyses and want
                     to save the database and point VirSorter to it in subsequent runs.
                     By default, this is off, and you should only specify this flag if
                     you are SURE you need it.
      --no_c         Use this option if you have issues with empty output files, i.e. 0
                     viruses predicted by VirSorter. This make VirSorter use a perl function
                     instead of the C script to calculate enrichment statistics. Note that
                     VirSorter will be slower with this option.
      --help         Show help and exit

$namespaces:
  s: http://schema.org/
  edam: http://edamontology.org/
$schemas:
  - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
  - name: "EMBL - European Bioinformatics Institute"
  - url: "https://www.ebi.ac.uk/"
