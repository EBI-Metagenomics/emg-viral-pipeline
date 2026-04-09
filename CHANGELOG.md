# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
