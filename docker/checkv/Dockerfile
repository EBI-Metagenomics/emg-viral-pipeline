FROM continuumio/miniconda3

LABEL base_image="continuumio/miniconda3"
LABEL version="1"
LABEL about.summary="CheckV is a fully automated command-line pipeline for assessing the quality of single-contig viral genomes, including identification of host contamination for integrated proviruses, estimating completeness for genome fragments, and identification of closed genomes."
LABEL about.license_file="https://bitbucket.org/berkeleylab/checkv/src/master/LICENSE.txt"
LABEL about.tags="virus quality"
LABEL about.home="https://bitbucket.org/berkeleylab/checkv"
LABEL software="CheckV"
LABEL software.version="0.8.1"

ENV VERSION 0.8.1

RUN conda install -c conda-forge -c bioconda --yes --freeze-installed \
    checkv=$VERSION && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete
