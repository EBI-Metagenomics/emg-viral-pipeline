# CWL viral pipeline

CWL implementation of the MGnify viral pipeline.

## Setup

It is possible to run the pipeline using docker/singularity or a conda env.

### Conda

Install [conda](https://docs.conda.io/en/latest/) and create an env using the `conda_env.yml` file:

**Rename the path in requirements/conda_env.yml to the desired env path**

```bash
conda env create -f requirements/conda_env.yml
```

The `init.sh` file is meant to set some env variables needed for the execution, this script is called from `virify.sh`.

### Docker/Singularity

After installing docker or singularity you will need some python package in you system:

```bash
pip install -r requirements/pip_requirements.txt
```

### Databases

In order to run the pipeline the following databases are required:

Everything is packed and ready to be used from EBI FTP:

```bash
./download-databases.sh -h

Download VIRify DBs for the CWL version
* requires rsyncimgvr_blast_swf.cwl

-f Output folder [mandatory]

```

## Running full pipeline from CLI

The pipeline users [toil](https://github.com/DataBiosphere/toil) as the CWL execution engine.

In order to run it use the helper script (provided you adjusted the paths on it).

```bash
$ ./virify.sh -h
```

## Structure of pipeline

![Diagram](img/pipeline.png)

# Tests

CWL tests are executed with [cwltest](https://github.com/common-workflow-language/cwltest).

Run:
```bash
cd tests
./cwltest.sh
```