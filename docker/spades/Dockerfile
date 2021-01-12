FROM continuumio/miniconda3
ENV VERSION 3.14
ENV TOOL spades

LABEL base_image="continuumio/miniconda3"
LABEL version="1"
LABEL about.summary="Spades assembler version 3.14"
LABEL about.license="SPDX:GPL-2.0-only"
LABEL about.tags="assembler"
LABEL about.home="http://cab.spbu.ru/software/spades/"
LABEL software="spades"
LABEL software.version="3.14"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt update && apt install -y procps wget gzip && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --add channels default

RUN conda install $TOOL=$VERSION && conda clean -a
