# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - [2026-08]

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
