![](https://img.shields.io/badge/CWL-magenta)
![](https://img.shields.io/badge/nextflow-20.01.0-brightgreen)
![](https://img.shields.io/badge/uses-docker-blue.svg)
![](https://img.shields.io/badge/uses-conda-yellow.svg)

# VIRify General
![Sankey plot](nextflow/figures/sankey.png)

TODO ...

# CWL

TODO ...

# Nextflow
Email: hoelzer.martin@gmail.com

A nextflow implementation of the VIRify pipeline for the detection of viruses from metagenomic assemblies.

## What do I need?

This pipeline runs with the workflow manager [Nextflow](https://www.nextflow.io/) using [Docker](https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce) (Conda will be implemented soonish, hopefully). All other programs and databases are automatically downloaded by Nextflow. _Attention_, the workflow will download databases with a size of roughly 49 GB the first time it is executed. 

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


## Basic execution

Simply clone this repository or get or update the workflow via Nextflow:
```bash
nextflow pull EBI-Metagenomics/emg-viral-pipeline
```

Get help:
```bash
nextflow run EBI-Metagenomics/emg-viral-pipeline --help
```

Run annotation for a small assembly file (takes approximately 30min + time for database download; ~49 GB):
````
nextflow run EBI-Metagenomics/emg-viral-pipeline --fasta '~/.nextflow/assets/EBI-Metagenomics/emg-viral-pipeline/test/assembly.fasta'
````

## Profiles

Per default, the workflow is run with Docker-support. When you execute the workflow on a HPC you can switch to 
* SLURM (``-profile slurm``)
* LSF (``-profile lsf``)
and then you should also define the parameters
* `--workdir` (here your work directories will be save)
* `--databases` (here your databases will be saved and the workflow checks if they are already available)
* `--cachedir` (here Docker/Singularity containers will be cached)

The `-profile conda` is not working at the moment until there is a conda recipe for PPR-Meta. Sorry. Use Docker. Please. 

## DAG chart

![DAG chart](nextflow/figures/chart.png)

