FROM quay.io/microbiome-informatics/miniconda:4.12.0

ENV VERSION 1.5.0
ENV TOOL PHANOTATE

LABEL base_image="microbiome-informatics/miniconda:4.12.0"
LABEL about.summary="PHANOTATE is a tool to annotate phage genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="python, phage, virus"
LABEL about.home="https://github.com/deprekate/PHANOTATE"
LABEL software="PHANOTATE"
LABEL software.version="1.5.0"
LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN mamba install -y -c conda-forge gcc && \
    pip install phanotate==${VERSION} \
    mamba remove -y gcc && conda clean -a
