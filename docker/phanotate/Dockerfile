FROM continuumio/miniconda3
ENV VERSION 1.2.2
ENV TOOL PHANOTATE

LABEL base_image="continuumio/miniconda3"
LABEL version="1" 
LABEL about.summary="PHANOTATE is a tool to annotate phage genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="python, phage, virus"
LABEL about.home="https://github.com/deprekate/PHANOTATE"
LABEL software="PHANOTATE"
LABEL software.version="1.2.2"
LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt update && apt install -y make gcc procps wget gzip && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --add channels default

RUN conda install trnascan-se=2.0.5 emboss=6.6.0 && conda clean -a

RUN git clone https://github.com/deprekate/$TOOL.git

WORKDIR "/${TOOL}"

RUN git clone https://github.com/deprekate/fastpath.git && make

ENV PATH="${PWD}:${PATH}"
