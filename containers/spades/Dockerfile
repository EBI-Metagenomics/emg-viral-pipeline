FROM quay.io/microbiome-informatics/miniconda:4.12.0

ENV VERSION 3.14
ENV TOOL spades

LABEL base_image="microbiome-informatics/miniconda:4.12.0"
LABEL version="1"
LABEL about.summary="Spades assembler version 3.14"
LABEL about.license="SPDX:GPL-2.0-only"
LABEL about.tags="assembler"
LABEL about.home="http://cab.spbu.ru/software/spades/"
LABEL software="spades"
LABEL software.version="3.14"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN conda install $TOOL=$VERSION && conda clean -a
