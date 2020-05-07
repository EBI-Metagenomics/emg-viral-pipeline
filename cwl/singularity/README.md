# PPR-Meta

Tool repo: [PPR-Meta](https://github.com/zhenchengfang/PPR-Meta)

We run this tool in a docker containter but not using CWL docker support. We wrapped the docker container in a bash script.

## Build Singularity

Build the image in a machine with sudo access (i.e. your workstation).

Tested with **singularity 2.6.1**

```bash
$ sudo singularity build pprmeta.simg pprmeta.singularity
```

### Rebuild

In order to rebuild the image but just to update changes in a particular section:

```bash
$ sudo singularity build --section environment pprmeta.simg pprmeta.singularity
```

## Run script

```bash
$ ./pprmeta.sh -f input.fasta -o pprmeta.csv
```

## Manually run

It's important to bind the dir with the files to the `/data` mount point. This is because PPR-Meta expects that folder to have the model files and a python script.

Arguments:
- `cleanenv` removes host env variables.
- `bind` mount the data path 

```bash
$ singularity run --cleanenv --bind /path-to-folder-with-files/:/data pprmeta.simg /data/<contigs.fasta> <output.csv>
```
