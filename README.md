![](https://img.shields.io/badge/CWL-1.2-green)
![](https://img.shields.io/badge/nextflow-22.04.5-brightgreen)
![](https://img.shields.io/badge/uses-docker-blue.svg)
![](https://img.shields.io/badge/uses-singularity-red.svg)
[![Build Status](https://travis-ci.com/EBI-Metagenomics/emg-viral-pipeline.svg?branch=master)](https://travis-ci.com/EBI-Metagenomics/emg-viral-pipeline)

<img align="right" width="140" height="140" src="figures/virify_logo.png">

1. [ The VIRify pipeline ](#virify)
2. [ Nextflow execution ](#nf)
3. [ CWL execution ](#cwl)
4. [ Pipeline overview ](#overview)
5. [ Detour: Metatranscriptomics ](#metatranscriptome)
6. [ Resources ](#resources)
7. [ Citations ](#cite)

<a name="virify"></a>

# VIRify
![Sankey plot](nextflow/figures/sankey.png)

## General
VIRify is a recently developed pipeline for the detection, annotation, and taxonomic classification of viral contigs in metagenomic and metatranscriptomic assemblies. The pipeline is part of the repertoire of analysis services offered by [MGnify](https://www.ebi.ac.uk/metagenomics/). VIRify's taxonomic classification relies on the detection of taxon-specific profile hidden Markov models (HMMs), built upon a set of 22,013 orthologous protein domains and [referred to as ViPhOGs](https://doi.org/10.3390/v13061164). 

The pipeline is implemented and available in [CWL](#cwl) and [Nextflow](#nf). You only need [CWL](#cwl) or [Nextflow](#nf) to run the pipeline (plus Docker or Singularity, as described below). For local execution and on HPCs we recommend the usage of [Nextflow](#nf). Details about installation and usage are given below.  


<a name="nf"></a>

# Nextflow

A [Nextflow](https://www.nextflow.io/) implementation of the VIRify pipeline. In the backend, the same scripts are used as in the [CWL](#cwl) implementation.

## What do I need?

This implementation of the pipeline runs with the workflow manager [Nextflow](https://www.nextflow.io/) and needs as second dependency either [Docker](https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce) or [Singularity](https://sylabs.io/guides/3.0/user-guide/quick_start.html). Conda will be implemented soonish, hopefully (currently blocked bc/ we use [PPR-Meta](https://github.com/zhenchengfang/PPR-Meta/issues/8)). However, we highly recommend in any way the usage of the stable containers. All other programs and databases are automatically downloaded by Nextflow. 

**Attention**, the workflow will download the containers and databases with a size of roughly 19 GB (49 GB with `--hmmextend` and `--blastextend`) the first time it is executed! 

### Install Nextflow
```bash
curl -s https://get.nextflow.io | bash
```
* for troubleshooting, see [more instructions about Nextflow](https://www.nextflow.io/). 

### Install Docker
If you dont have experience with bioinformatic tools and their installation just copy the commands into your terminal to set everything up (local machine with full permissions!):
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -a -G docker $USER
```
* restart your computer
* for troubleshooting, see [more instructions about Docker](https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce)

### Install Singularity

While singularity can be installed via Conda, we recommend setting up a _true_ Singularity installation. For HPCs, ask the system administrator you trust. [Here](https://github.com/hpcng/singularity/blob/master/INSTALL.md) is also a good manual to get you started. _Please note_: you only need Docker or Singularity. However, due to security concerns it might not be possible to use Docker on your shared machine or HPC.

## Basic execution

While it is possible to clone this repository and directly execute the `virify.nf`We _recommended_ to let Nextflow handle the installation. Get the pipeline code via:
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


<a name="cwl"></a>

# Common Workflow Language
VIRify was implemented in [Common Workflow Language (CWL)](https://www.commonwl.org/). 

## What do I need?
The current implementation uses CWL version 1.2. It was tested using Toil version 5.3.0 as the workflow engine and conda to manage the software dependencies.

## How?
For instructions go to the [CWL README](cwl/README.md)


<a name="overview"></a>

# Pipeline overview
![VIRify Overview](nextflow/figures/virify_fig1_workflow.png)
For further details please check: [doi.org/10.1101/2022.08.22.504484](https://doi.org/10.1101/2022.08.22.504484)


<a name="metatranscriptome"></a>

# A note about metatranscriptomes

Although VIRify has been benchmarked and validated with metagenomic data in mind, it is also possible to use this tool to detect RNA viruses in metatranscriptome assemblies (e.g. SARS-CoV-2). However, some additional considerations for this purpose are outlined below:

**1. Quality control:** As for metagenomic data, a thorough quality control of the FASTQ sequence reads to remove low-quality bases, adapters and host contamination (if appropriate) is required prior to assembly. This is especially important for metatranscriptomes as small errors can further decrease the quality and contiguity of the assembly obtained. We have used [TrimGalore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) for this purpose.

**2. Assembly:** There are many assemblers available that are appropriate for either metagenomic or single-species transcriptomic data. However, to our knowledge, there is no assembler currently available specifically for metatranscriptomic data. From our preliminary investigations, we have found that transcriptome-specific assemblers (e.g. [rnaSPAdes](http://cab.spbu.ru/software/spades/)) generate more contiguous and complete metatranscriptome assemblies compared to metagenomic alternatives (e.g. [MEGAHIT](https://github.com/voutcn/megahit/releases) and [metaSPAdes](http://cab.spbu.ru/software/spades/)).

**3. Post-processing:** Metatranscriptomes generate highly fragmented assemblies. Therefore, filtering contigs based on a set minimum length has a substantial impact in the number of contigs processed in VIRify. It has also been observed that the number of false-positive detections of [VirFinder](https://github.com/jessieren/VirFinder/releases) (one of the tools included in VIRify) is lower among larger contigs. The choice of a length threshold will depend on the complexity of the sample and the sequencing technology used, but in our experience any contigs <2 kb should be analysed with caution.

**4. Classification:** The classification module of VIRify depends on the presence of a minimum number and proportion of phylogenetically-informative genes within each contig in order to confidently assign a taxonomic lineage. Therefore, short contigs typically obtained from metatranscriptome assemblies remain generally unclassified. For targeted classification of RNA viruses (for instance, to search for Coronavirus-related sequences), alternative DNA- or protein-based classification methods can be used. Two of the possible options are: (i) using [MashMap](https://github.com/marbl/MashMap/releases) to screen the VIRify contigs against a database of RNA viruses (e.g. Coronaviridae) or (ii) using [hmmsearch](http://hmmer.org/download.html) to screen the proteins obtained in the VIRify contigs against marker genes of the taxon of interest.


<a name="resources"></a>

# Resources

Additional material as well as the ViPhOG HMMs used in VIRify are available at [osf.io/fbrxy](https://osf.io/fbrxy/).

Here, we list databases used and automatically downloaded by the pipeline during first execution. We deposited most database files on a separate FTP to ensure accessibility. The files can be also downloaded manually and then used as an input for the pipeline to prevent auto-download (see `--help`).

### Virus-specific protein profile HMMs

* **ViPhOGs** (mandatory, used for taxonomy assignment)
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpHMM_database_v3.tar.gz`
* **pVOGs** (optional)
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/pvogs.tar.gz`
* **RVDB** (optional)
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/rvdb.tar.gz`
* **VOGDB** (optional)
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vogdb.tar.gz`
* **VPF** (optional)
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/hmmer_databases/vpf.tar.gz`

### Initial virus prediction on contig level

* **VirSorter** HMMs
    * `wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virsorter-data-v2.tar.gz`
* **Virfinder** model
    * `wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/virfinder/VF.modEPV_k8.rda`

### Virus prediction QC

* **CheckV**
    * `wget https://portal.nersc.gov/CheckV/checkv-db-v1.0.tar.gz`
    * PAPER

### Taxonomy annotation

* **NCBI taxonomy**
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/2020-07-01_ete3_ncbi_tax.sqlite.gz`

### Blast-based assignment (optional)

* **IMG/VR**
    * `wget -nH ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/IMG_VR_2018-07-01_4.tar.gz`



<a name="cite"></a>

# Cite

If you use the pipeline or ViPhOG HMMs in your work, please cite accordingly:

**ViPhOGs:**

[Moreno-Gallego, Jaime Leonardo, and Alejandro Reyes. "Informative regions in viral genomes." _Viruses_ 13.6 (2021): 1164.](https://www.mdpi.com/1999-4915/13/6/1164)

**VIRify:** 

[Rangel-Pineros, Guillermo, et al. "VIRify: an integrated detection, annotation and taxonomic classification pipeline using virus-specific protein profile hidden Markov models." _bioRxiv_ (2022)](https://doi.org/10.1101/2022.08.22.504484)
