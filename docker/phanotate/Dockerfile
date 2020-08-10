FROM python:3.8-slim
ENV VERSION 1.5.0
ENV TOOL PHANOTATE

LABEL base_image="python/3.8-slim"
LABEL version="1" 
LABEL about.summary="PHANOTATE is a tool to annotate phage genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="python, phage, virus"
LABEL about.home="https://github.com/deprekate/PHANOTATE"
LABEL software="PHANOTATE"
LABEL software.version="v1.5.0"
LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt update && apt install -y make gcc git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone --branch '1.5.0' --depth 1 https://github.com/deprekate/$TOOL.git

WORKDIR "/${TOOL}"

RUN python3 setup.py install 

ENV PATH="${PWD}:${PATH}"