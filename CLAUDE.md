# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VIRify is a Nextflow DSL2 pipeline for detection, annotation, and taxonomic classification of viral contigs in metagenomic assemblies. It is part of EBI's MGnify services. Requires Nextflow >=24.04.0.

## Commands

### Running the pipeline

```bash
# With a FASTA file (single sample)
nextflow run main.nf -profile standard --fasta input.fasta --output results/

# With a samplesheet (multiple samples)
nextflow run main.nf -profile standard --samplesheet samples.csv --output results/

# With Docker explicitly
nextflow run main.nf -profile docker,local --fasta input.fasta --output results/
```

### Running tests

All tests are Python-based (pytest). The pipeline itself runs in Docker — do not run Python scripts directly.

```bash
# Run all unit tests
pytest tests/

# Run a single test file
pytest tests/test_parse_viral_preds.py

# Run a specific test
pytest tests/test_parse_viral_preds.py::test_function_name -v
```

### Linting / formatting

```bash
# Format Python scripts in bin/
black bin/

# Check without modifying
black --check bin/
```

## Architecture

### Workflow structure

```
main.nf                         Entry point: validates params, runs VIRIFY workflow
workflows/virify.nf             Main workflow (orchestrates all subworkflows)
subworkflows/local/             Modular subworkflows
modules/local/                  Individual tool wrappers (one per tool)
bin/                            Python/R/Ruby helper scripts called by modules
```

### Workflow stages in `virify.nf`

1. **DOWNLOAD_DATABASES** — auto-downloads ~19 GB of databases to `nextflow-autodownload-databases/` on first run
2. **ASSEMBLE_ILLUMINA** — optional assembly from raw reads (SPAdes); triggered by `--assemble`
3. **PREPROCESS** — length filtering (`--min-len`) and FASTA header sanitization
4. **DETECT** — viral contig prediction via VirSorter, VirFinder, PPR-Meta
5. **ANNOTATE** — Prodigal protein prediction → HMMER HMM search → ratio/evalue filtering → taxonomy assignment → CheckV quality → GFF output
6. **PLOT** — Krona, Sankey visualizations; optional chromomap and balloon plots

### Key subworkflows

- `subworkflows/local/annotate.nf` — core annotation logic, the most complex subworkflow
- `subworkflows/local/hmmer_processing.nf` — chunks protein FASTA for parallel HMM search
- `subworkflows/local/download_databases.nf` — local cache or cloud preload for databases

### Outputs

Results are staged into numbered directories in `--output`:
- `01-predictions/` — per-tool viral predictions
- `02-prodigal/` — protein predictions
- `03-hmmer/` — HMM search results
- `04-blast/` — optional BLAST results
- `05-plots/` — Krona/Sankey charts
- `06-taxonomy/` — taxonomic assignments
- `07-checkv/` — CheckV quality assessments
- `08-final/` — GFF files, filtered contigs, final taxonomy tables

### Important bin/ scripts

- `parse_viral_pred.py` — merges and parses output from all three prediction tools
- `viral_contigs_annotation.py` — processes HMM hits into annotation tables
- `contig_taxonomic_assign.py` — assigns taxonomy using ViPhOG HMM profiles
- `write_viral_gff.py` — generates GFF3 output

### Configuration

- `nextflow.config` — main config with profiles and default params
- `configs/base.config` — resource labels: `process_single`, `process_low`, `process_medium`, `process_high`
- `configs/modules.config` — per-module container images (quay.io registry)
- Parameter schema: `nextflow_schema.json` (validated via nf-schema plugin v2.7.1)

### Containers

All tools run in Docker/Singularity containers defined in `configs/modules.config`. Container Dockerfiles are in `containers/`. Conda is not fully supported (PPR-Meta lacks a conda package).

### Input formats

- Single FASTA: `--fasta <path>`
- Samplesheet CSV columns: `id, assembly, fastq_1, fastq_2, proteins`
  - `fastq_1`/`fastq_2` only needed with `--assemble`
  - `proteins` accepts pre-called Prodigal-format proteins (header: `>contig_1 # start # end # strand # ...`)

### Key flags

| Flag | Description |
|---|---|
| `--virome` | Relaxed thresholds for virome samples |
| `--onlyannotate` | Skip detection, annotate all input contigs |
| `--hmmextend` | Use extended HMM database |
| `--blastextend` | Run optional BLAST against extended DBs |
| `--assemble` | Assemble from raw reads before detection |
| `--chromomap` / `--balloon` | Enable optional visualization outputs |

## Testing notes

- Test data lives in `tests/test_data/` and `tests/parse_viral_fixtures/`
- Test dependencies are in `requirements-test.txt` (pytest, pandas, ete3, biopython, ruamel.yaml)
- CI runs on push/PR to master and dev branches via `.github/workflows/unit_tests.yml`
- nf-test is not yet set up — only Python unit tests exist for the `bin/` scripts
