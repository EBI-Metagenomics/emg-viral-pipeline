# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VIRify is a Nextflow DSL2 pipeline for detection, annotation, and taxonomic classification of viral
contigs in metagenomic/metatranscriptomic assemblies. Part of EBI's MGnify services. Current version
is 4.0.0; requires Nextflow >= 25.10.0.

Taxonomic classification relies on ViPhOG HMM profiles (22,013 orthologous viral protein domains).

## Commands

### Running the pipeline

Input is **always** a samplesheet CSV (`--fasta` was removed in 4.0.0). A profile is a merged pair of
*executor* (`local`, `lsf`, `slurm`) and *engine* (`docker`, `singularity`); `standard` is a
pre-merged `local` + `docker`.

```bash
nextflow run main.nf -profile local,docker --samplesheet samplesheet.csv --output results/
```

First run downloads ~19 GB of databases (49 GB with `--hmmextend --blastextend`) into
`nextflow-autodownload-databases/`; point `--databases` at an existing directory to reuse them.

The `conda` profile is broken by design — PPR-Meta has no conda package. Use Docker or Singularity.

### Python unit tests

`pytest.ini` puts `bin/` on `pythonpath`, so tests import the `bin/` scripts as modules directly.

```bash
pytest                                          # all tests (what CI runs)
pytest tests/test_write_gff.py
pytest tests/test_write_gff.py::test_name -v
```

### nf-test

nf-test covers the subworkflows (`subworkflows/local/*/tests/`) and the top-level workflow
(`workflows/tests/`). Tests are tagged: `subworkflows`, `pipeline`, plus a per-target tag
(`predict_proteins`, `proteins_compatibility`, `virify`).

`nf-test.config` declares `profile = "test"`, but **no `test` profile exists in nextflow.config** —
always override it explicitly or Nextflow will fail on an unknown profile:

```bash
nf-test test --tag subworkflows --profile docker,local
```

### Linting / formatting

`pre-commit` (ruff --fix, black, whitespace/EOF/yaml hooks) is the gate — `pre-commit run -a` is
exactly what CI runs. `.flake8` sets `max-line-length = 99`. Bulk-formatting commits are listed in
`.git-blame-ignore-revs`.

```bash
pre-commit run -a
```

## Architecture

### Layout

```
main.nf                       Validates params (nf-schema), calls VIRIFY
workflows/virify.nf           Orchestrates everything; owns the channel plumbing
subworkflows/local/           Stage subworkflows; newer ones use nf-core layout (dir/main.nf + meta.yml + tests/)
modules/local/<name>/main.nf  Tool wrappers
modules/nf-core/              Vendored nf-core modules, tracked in modules.json
bin/                          Python/R/Ruby/shell scripts invoked by modules
```

### The central abstraction: confidence categories

After `DETECT`, every downstream channel carries a `set_name` (a.k.a. `confidence_set_name`)
alongside `meta`. There are exactly three: `high_confidence_viral_contigs`,
`low_confidence_viral_contigs`, `prophages`. Most channels are therefore keyed on `[meta, set_name]`
(note the `by: [0,1]` joins in `annotate.nf`), and results are only collapsed back to per-sample
lists via `groupTuple()` just before `WRITE_GFF`. Getting this key wrong is the usual cause of
silently dropped or cross-joined records.

### Flow through `workflows/virify.nf`

1. **DOWNLOAD_DATABASES** — one `get_db` module per database (`modules/local/get_db/*.nf`); each
   takes a local-path param and a download-link param.
2. **PREPROCESS** — length filter (`--length`, in kb) then `RENAME` contigs to short synthetic names,
   emitting a `mapfile`. Everything downstream operates on renamed contigs; `RESTORE` maps names back.
3. **Protein resolution** — the samplesheet may supply `proteins_gff` + `proteins_faa`. Records
   *without* them go to `PREDICT_PROTEINS` (pyrodigal → `RENAME_PRODIGAL`); records *with* them go to
   `PROTEINS_COMPATIBILITY`, which branches into `matched` / `require_rename` / `not_matched`.
   `not_matched` samples are **dropped from the run** and reported in
   `${output}/not_matched_proteins_report.tsv`. The three surviving streams are mixed back into one.
4. **DETECT** — assembly is chunked (`--chunk_fasta_size`), run through VirSorter2 (or VirSorter v1
   under `--use_virsorter_v1`), VirFinder and PPR-Meta, chunk outputs concatenated, then `PARSE`
   assigns contigs to the three confidence categories.
5. **SPLIT_PROTEINS** — splits the per-sample faa/gff into per-category faa/gff.
6. **ANNOTATE** — `HMMER_PREDICTION` (seqkit-split chunking → hmmsearch vs ViPhOG → concat →
   postprocess) → `RATIO_EVALUE` → `ANNOTATION` → `ASSIGN` (lineages) → `CHECKV` → `WRITE_GFF` →
   bgzip/tabix. Optional: `BLAST` (IMG/VR), `MASHMAP`, `PLOT_CONTIG_MAP`.
7. **PLOT** — Krona and Sankey; optional chromomap/balloon.

`WRITE_GFF` runs `gt gff3validator` on its own output, so malformed contig names fail the pipeline
there rather than silently producing bad GFF (see `docs/development.md` on header sanitization).

### Protein/contig linkage

Since 4.0.0, protein-to-contig linkage is derived from the **GFF**, not from protein header parsing.
Only contigs carry the `|viral_sequence` / `|prophage-<start>:<end>` suffixes; proteins do not.
`RENAME_PRODIGAL` exists because prodigal/pyrodigal writes `ID=<digit>_<digit>` in the GFF, which is
rewritten back to the faa header's protein name.

### Configuration

- `nextflow.config` — params, profiles, manifest, plugins (`nf-schema@2.7.1`).
- `configs/base.config` — resource labels: `process_single`, `process_low`, `process_medium`,
  `process_high`, `process_long`, `process_high_memory`, `error_ignore`, `error_retry`.
- `configs/modules.config` — per-process `publishDir` and `ext` args. Most publish blocks are gated
  on `enabled: params.publish_all`; only `08-final` content is published by default.
- Containers are declared **in each module's `main.nf`** (quay.io / seqera wave), not in
  modules.config. Dockerfiles for the custom images live in `containers/`.
- `nextflow_schema.json` + `assets/schema_input.json` validate params and the samplesheet.

### Samplesheet

Columns: `id`, `assembly` (required), `proteins_gff`, `proteins_faa`. The latter two are
`dependentRequired` — supply both or neither. `.gz` accepted throughout.

### Outputs

Results are per-sample: `${output}/${meta.id}/<numbered dir>/`. Default published output is
`08-final/` (annotation, contigs, gff, krona, sankey); `--publish_all` additionally emits
`01-predictions`, `02-protein-prediction`, `03-hmmer`, `04-blast`, `05-plots`, `06-taxonomy`,
`07-checkv`. Directory names come from the `*dir` params in `nextflow.config`.

### Key flags

| Flag | Description |
|---|---|
| `--virome` | Relaxed detection thresholds for virome samples |
| `--publish_all` | Publish intermediate stage directories, not just `08-final` |
| `--hmmextend` | Additionally search RVDB / pVOGs / VOGDB / VPF HMMs |
| `--blastextend` | Run BLAST against IMG/VR |
| `--use_virsorter_v1` | Use VirSorter v1 instead of VirSorter2 |
| `--mashmap <ref>` | Screen contigs against a reference with MashMap |
| `--chromomap` / `--balloon` | Optional visualization outputs |
| `--length` | Min contig length in **kb** (default 1.5) |

Removed in 4.0.0 — do not reintroduce or reference: `--fasta`, `--assemble`, `--onlyannotate`,
`--use_proteins`, and the `FILTER_PROTEINS_IN_CONTIGS` step.

## Important bin/ scripts

- `parse_viral_pred.py` — merges VirSorter/VirFinder/PPR-Meta output into the three categories
- `check_proteins_compatibility.py` — validates a user-supplied fasta/faa/gff triplet
- `split_proteins_by_categories.py` — splits faa/gff per confidence category
- `viral_contigs_annotation.py` — HMM hits → annotation tables
- `contig_taxonomic_assign.py` — lineage assignment from ViPhOG hits
- `write_viral_gff.py` — final GFF3
- `rename_fasta.py` / `rename_prodigal.py` / `restore_virsorter_fastas.py` — the rename/restore cycle

## Testing notes

- Fixtures sit next to their test in `tests/<name>/` or `tests/*_fixtures/`; nf-test data lives in
  each subworkflow's `tests/data/`.
- `requirements.txt` is the runtime Python set; `requirements-test.txt` adds pytest.
- CI (`.github/workflows/`): `unit_tests.yml` (pytest, py3.10), `lint.yml` (pre-commit, py3.12),
  `nf-test-subwf.yml` (nf-test, `--tag subworkflows`). All trigger on push/PR to `master` only.

## Updating vendored nf-core modules

`modules.json` pins each nf-core module to a `git_sha`. Use `nf-core modules update <name>` rather
than hand-editing `modules/nf-core/`; `.nf-core.yml` marks this repo as `repository_type: pipeline`.
