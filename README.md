![](https://img.shields.io/badge/CWL-1.2-green)
![](https://img.shields.io/badge/nextflow-21.04.0-brightgreen)
![](https://img.shields.io/badge/uses-docker-blue.svg)
![](https://img.shields.io/badge/uses-singularity-red.svg)
![](https://img.shields.io/badge/uses-conda-yellow.svg)
[![Build Status](https://travis-ci.com/EBI-Metagenomics/emg-viral-pipeline.svg?branch=master)](https://travis-ci.com/EBI-Metagenomics/emg-viral-pipeline)

<img align="right" width="140" height="140" src="figures/virify_logo.png">

1. [ VIRify pipeline ](#virify)
2. [ CWL execution ](#cwl)
3. [ Nextflow execution ](#nf)

<a name="virify"></a>

# VIRify
![Sankey plot](nextflow/figures/sankey.png)
VIRify is a recently developed pipeline for the detection, annotation, and taxonomic classification of viral contigs in metagenomic and metatranscriptomic assemblies. The pipeline is part of the repertoire of analysis services offered by [MGnify](https://www.ebi.ac.uk/metagenomics/). VIRify’s taxonomic classification relies on the detection of taxon-specific profile hidden Markov models (HMMs), built upon a set of 22,014 orthologous protein domains and [referred to as ViPhOGs](https://doi.org/10.3390/v13061164). 

The pipeline is implemented and available in [CWL](#cwl) and [Nextflow](#nf).

<a name="cwl"></a>

# Common Workflow Language
VIRify was implemented in [Common Workflow Language (CWL)](https://www.commonwl.org/). 

## What do I need?

The current implementation uses CWL version 1.2. It was tested using Toil version 5.3.0 as the workflow engine and conda to manage the software dependencies.

## How?

For instructions go to the [CWL README](cwl/README.md)

<a name="nf"></a>

# Nextflow

A Nextflow implementation of the VIRify pipeline. In the backend, the same scripts are used as in the CWL implementation.

## What do I need?

This pipeline runs with the workflow manager [Nextflow](https://www.nextflow.io/) and needs as second dependency either [Docker](https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce) or [Singularity](https://sylabs.io/guides/3.0/user-guide/quick_start.html). Conda will be implemented soonish, hopefully. However, we highly recommend the usage of the stable containers. All other programs and databases are automatically downloaded by Nextflow. _Attention_, the workflow will download databases with a size of roughly 19 GB (49 GB with `--hmmextend` and `--blastextend`) the first time it is executed. 

### Install Nextflow
```bash
curl -s https://get.nextflow.io | bash
```
* see [more instructions about Nextflow](https://www.nextflow.io/). 

### Install Docker
If you dont have experience with bioinformatic tools and their installation just copy the commands into your terminal to set everything up:
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -a -G docker $USER
```
* restart your computer
* see [more instructions about Docker](https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce)

### Install Singularity

While singularity can be installed via Conda, we recommend setting up a _true_ Singularity installation. For HPCs, ask the system administrator you trust. [Here](https://github.com/hpcng/singularity/blob/master/INSTALL.md) is also a good manual to get you started. _Please note_: you only need Docker or Singularity. 

## Basic execution

Simply clone this repository and execute `virify.nf`:
```bash
git clone https://github.com/EBI-Metagenomics/emg-viral-pipeline.git
cd emg-viral-pipeline
nextflow run virify.nf --help
```

or (__recommended__) let Nextflow handle the installation. With the same command you can update the pipeline.
```bash
nextflow pull EBI-Metagenomics/emg-viral-pipeline
```

Get help:
```bash
nextflow run EBI-Metagenomics/emg-viral-pipeline --help
```

We __highly recommend__ to run stable releases, also for reproducibility:
```bash
nextflow run EBI-Metagenomics/emg-viral-pipeline -r v0.2.0 --help
```

Run annotation for a small assembly file (10 contigs, 0.78 Mbp) on your local machine using Docker containers (per default `--cores 4`; takes approximately 10 min on a 8 core i7 laptop + time for database download; ~19 GB):
```bash
nextflow run EBI-Metagenomics/emg-viral-pipeline -r v0.2.0 --fasta "/home/$USER/.nextflow/assets/EBI-Metagenomics/emg-viral-pipeline/nextflow/test/assembly.fasta" --cores 4 -profile local,docker
```

__Please note__ that in particular further parameters such as 

* `--workdir` or `-w` (here your work directories will be save)
* `--databases` (here your databases will be saved and the workflow checks if they are already available)
* `--singularity_cachedir` (here Singularity containers will be cached, not needed for Docker, default: 'singularity')

are important to handle where Nextflow writes files. 

Execution specific for the EBI cluster:
```bash
source /hps/nobackup2/production/metagenomics/virus-pipeline/CONFIG 

# recommended run example to easily resume a run later and to have all run-related .nextflow.log files in the correct folder
OUTPUT=/path/to/output/dir
mkdir -p $OUTPUT
DIR=$PWD
cd $OUTPUT
# this will pull the pipeline if it is not already available
# use `nextflow pull EBI-Metagenomics/emg-viral-pipeline` to update the pipeline
nextflow run EBI-Metagenomics/emg-viral-pipeline -r v0.2.0 \
--fasta "/homes/$USER/.nextflow/assets/EBI-Metagenomics/emg-viral-pipeline/nextflow/test/assembly.fasta" \
--output $OUTPUT --workdir $OUTPUT/work --databases $DATABASES \
--singularity_cachedir $SINGULARITY -profile ebi
cd $DIR
```


## Profiles

Nextflow uses a merged profile handling system so you have to define an executor (e.g., `local`, `lsf`, `slurm`) and an engine (`docker`, `singularity`) to run the pipeline according to your needs and infrastructure 

Per default, the workflow runs locally (e.g. on your laptop) with Docker. When you execute the workflow on a HPC you can for example switch to a specific job scheduler and Singularity instead of Docker:

* SLURM (``-profile slurm,singularity``)
* LSF (``-profile lsf,singularity``)

Dont forget, especially on an HPC, to define further important parameters such as

* `--workdir` or `-w` (here your work directories will be save)
* `--databases` (here your databases will be saved and the workflow checks if they are already available)
* `--singularity_cachedir` (here Singularity containers will be stored, default 'singularity')

The engine `conda` is not working at the moment until there is a conda recipe for PPR-Meta. Sorry. Use Docker. Please. Or install PPR-Meta by yourself and then use the `conda` profile.  

## DAG chart

![DAG chart](nextflow/figures/chart.png)

# A note about metatranscriptomes

Although VIRify has been benchmarked and validated with metagenomic data in mind, it is also possible to use this tool to detect RNA viruses in metatranscriptome assemblies (e.g. SARS-CoV-2). However, some additional considerations for this purpose are outlined below:

<b>1. Quality control:</b> As for metagenomic data, a thorough quality control of the FASTQ sequence reads to remove low-quality bases, adapters and host contamination (if appropriate) is required prior to assembly. This is especially important for metatranscriptomes as small errors can further decrease the quality and contiguity of the assembly obtained. We have used [TrimGalore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) for this purpose.

<b>2. Assembly:</b> There are many assemblers available that are appropriate for either metagenomic or single-species transcriptomic data. However, to our knowledge, there is no assembler currently available specifically for metatranscriptomic data. From our preliminary investigations, we have found that transcriptome-specific assemblers (e.g. [rnaSPAdes](http://cab.spbu.ru/software/spades/)) generate more contiguous and complete metatranscriptome assemblies compared to metagenomic alternatives (e.g. [MEGAHIT](https://github.com/voutcn/megahit/releases) and [metaSPAdes](http://cab.spbu.ru/software/spades/)).

<b>3. Post-processing:</b> Metatranscriptomes generate highly fragmented assemblies. Therefore, filtering contigs based on a set minimum length has a substantial impact in the number of contigs processed in VIRify. It has also been observed that the number of false-positive detections of [VirFinder](https://github.com/jessieren/VirFinder/releases) (one of the tools included in VIRify) is lower among larger contigs. The choice of a length threshold will depend on the complexity of the sample and the sequencing technology used, but in our experience any contigs <2 kb should be analysed with caution.

<b>4. Classification:</b> The classification module of VIRify depends on the presence of a minimum number and proportion of phylogenetically-informative genes within each contig in order to confidently assign a taxonomic lineage. Therefore, short contigs typically obtained from metatranscriptome assemblies remain generally unclassified. For targeted classification of RNA viruses (for instance, to search for Coronavirus-related sequences), alternative DNA- or protein-based classification methods can be used. Two of the possible options are: (i) using [MashMap](https://github.com/marbl/MashMap/releases) to screen the VIRify contigs against a database of RNA viruses (e.g. Coronaviridae) or (ii) using [hmmsearch](http://hmmer.org/download.html) to screen the proteins obtained in the VIRify contigs against marker genes of the taxon of interest.

# Cite

If you use VIRify in your work, please cite:

[TBA](https://www.lipsum.com/)