FROM quay.io/microbiome-informatics/miniconda:4.12.0

LABEL base_image="microbiome-informatics/miniconda:4.12.0"
LABEL version="1"
LABEL about.summary="VirSorter: mining viral signal from microbial genomic data"
LABEL about.license="SPDX:GPL-2.0-only"
LABEL about.tags="virus"
LABEL about.home="https://github.com/simroux/VirSorter"
LABEL software="VirSorter"
LABEL software.version="1.0.6_edfeb8c5e72"

ENV VERSION 1.0.6_edfeb8c5e72

RUN conda create -n virsorter python=3.6 --yes 

ENV CONDA_DEFAULT_ENV virsorter

RUN conda install -c bioconda --yes \
    perl \
    blast \
    diamond=0.9.14 \
    hmmer=3.1b2 \
    mcl=14.137 \
    metagene_annotator \
    muscle \
    perl-bioperl \
    perl-file-which \
    perl-list-moreutils \
    perl-parallel-forkmanager \
    && conda clean -afy

WORKDIR /opt

RUN git clone https://github.com/simroux/VirSorter.git && \
    cd VirSorter/Scripts && \
    git checkout edfeb8c5e72

RUN /bin/bash -c conda activate virsorter

ENV PATH=/opt/conda/envs/virsorter/bin:$PATH:/opt/VirSorter:/opt/VirSorter/Scripts:${PATH}
