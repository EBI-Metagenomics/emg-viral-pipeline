# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - [2026-11-27]

### Fixed
- Each contig is now in one category only. With VirSorter2, a contig could be a prophage (`PP`) and
  also a high or low confidence contig (`HC` or `LC`), and the GFF had features for both. The
  priority is now `HC` > `PP` > `LC`, the same as with VirSorter v1. Known limit: when a prophage
  keeps no CDS, the contig is not in the GFF, also when a dropped `LC` call would have kept it.
- GFF: CheckV rows are now linked by the full sequence ID, with the prophage suffix. Before, the
  `LC` and `PP` rows of a contig used the same key, and the file order decided which CheckV values
  each feature got.
- GFF: each CDS is written once. A CDS inside a prophage region gets `PP`.
- GFF: the `virify_quality` label now comes from the category file name. Before, a sequence with no
  CheckV row got `unknown`.
- High and low confidence viral contigs from VirSorter2 now hold the full assembly contig. Before,
  `*_original.fasta` had the VirSorter2-trimmed sequence under the full contig name, so the FASTA
  did not agree with the proteins, the annotation and the GFF region. CheckV now runs on the same
  sequence as the annotation.
- Pipeline no longer fails when a predicted viral contig has no proteins. `split_proteins` now always
  writes its per-category GFF, instead of skipping it when nothing matched and leaving `SPLIT_PROTEINS`
  without a declared output.
- Viral contigs with no proteins are no longer silently lost. They are discarded deliberately and
  listed in a per-step `*_no_proteins.tsv` report, published to `08-final` with `--publish_all` and
  only written when that step actually dropped a contig.

### Added
- **Filter contigs without proteins** step: contigs with no CDS in the proteins GFF are dropped before
  the viral prediction tools run. As a side effect, samples whose supplied proteins do not match their
  assembly no longer run the detection tools before being discarded.
- Categories left with no proteins after prophage coordinate filtering are dropped before annotation.
  A prophage interval can contain no CDS even on a protein-rich contig, and neither `seqkit split2`
  nor `hmmsearch` tolerates an empty protein FASTA.
- A warning when every viral category of a sample loses all of its proteins, since such a sample
  produces no final GFF.
- nf-test coverage for `SPLIT_PROTEINS` and the new `FILTER_NO_PROTEINS` module, and unit tests for the
  `--output-gff` output, which was previously untested.
- `08-final/<id>_detection_evidence.tsv`, always published: one row per `HC`, `LC` and `PP`
  sequence, with the rule that set its category, the calls that VIRify did not keep
  (`dropped_calls`), and the VirFinder, PPR-Meta and CheckV values.
- Docs: the GFF attributes, and how VIRify selects one category when the prediction tools disagree.

### Changed
- The CheckV summaries (`07-checkv`) and the detection tool results in `01-predictions` are now
  always published, not only with `--publish_all`: the VirSorter2 score, boundary and metadata
  tables, `virfinder/<id>_virfinder.tsv` and `pprmeta/<id>_pprmeta.csv`.
- VirFinder and PPR-Meta results are now published as one table per sample, merged from the
  assembly chunks. The per-chunk files are no longer published.

## [4.0.0] - [2026-08-08]

### Removed
- Mode `--assemble`. Pipeline now accepts only FASTA file as main input, no reads support anymore.
- Mode `--onlyannotate`. Detection step has become mandatory.
- Flag `--use_proteins`. There is no need to specify that flag anymore. Proteins can be provided in input `--samplesheet`. If nothing was provided per record - pipeline will run protein prediction step.
- Argument `--fasta`. Input contigs should be provided only with `--samplesheet`.
- `FILTER_PROTEINS_IN_CONTIGS` step
- environment variable `CONTIGS` and `contig_number`
- viral identifier from proteins headers. Now only contigs have `|viral_sequence` or `|prophage` identifiers

### Replaced
- `Prodigal` replaced with `pyrodigal`

### Fixed
- Download databases process. Separated each database input.
- Changed protein-related steps to make protein-contig linkage from GFF file (ex. split_proteins, annotate, assign)
- Bug in `write_gff` not publishing all proteins related to viral/prophage record.
- Bug in `write_gff` not processing data if all inputs (quality, annotation and assignment) were not provided.

### Added
- `proteins_faa` and `proteins_gff` fields to input samplesheet. Now if user wants to provide already predicted proteins - those should be provided in `faa` **and** `gff` files.
- **Proteins compatibility** step: checks validity of protein files + tests.
- **Rename prodigal** step. Prodigal sometimes renamed proteins into `digit_digit` format in `ID=` field in GFF. Those records are renamed back to original protein name.
- **GitHub actions**: linting, pytest, nf-test for subworkflow
- **Docs**: development, output and usage. Simplified README, changed pipeline schema, added schema `.svg`
- More unit tests
- `requrements.txt`

## [3.3.2] - [2026-06-09]

### Added

- Performance improvements: chunking of input fasta for VirFinder and PPRMeta to use parallelisation ([#176](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/176))
- Optimisation of SPLIT_PROTEINS module ([#171](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/171))

### Fixed

- Set circularity of prophages detected by VirSorter2 to `linear` ([#176](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/176))

## [3.3.1] - [2026-04-09]

### Fixed

- [nf-schema](https://github.com/nextflow-io/nf-schema) plugin was missing from the pipeline dependencies, which broke the pipeline if the plugin was missing from the env.
  It also caused the pipeline to randomly fail at times (the error was during the validation of the parameters) [#169](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/169)

## [3.3.0] - [2026-03-04]

### Added

- Support for compressed FASTA and user-provided protein files (`.gz`) ([#165](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/165))
- Filter step to remove user-provided proteins that do not belong to any contig in the assembly ([#168](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/168))

### Fixed

- GFF generation would omit contigs when user-provided proteins were supplied ([#167](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/167))
- Annotation step failed when proteins had non-Prodigal headers (e.g. FragGeneScan) ([#166](https://github.com/EBI-Metagenomics/emg-viral-pipeline/pull/166))
