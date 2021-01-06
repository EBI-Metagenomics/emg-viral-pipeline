FROM continuumio/miniconda3
ENV VERSION 2.9.0 
ENV TOOL blast

LABEL base_image="continuumio/miniconda3"
LABEL version="1"
LABEL software="NCBI BLAST+"
LABEL software.version="2.9.0"
LABEL about.summary="basic local alignment search tool"
LABEL about.home="http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastHome"
LABEL about.documentation="http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastHome"
LABEL about.license_file="https://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/lxr/source/scripts/projects/blast/LICENSE"
LABEL about.license="SPDX:MIT"
LABEL about.tags="genomics"

RUN apt update && apt install -y procps wget gzip && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --add channels default

RUN conda install -y $TOOL=$VERSION && conda clean -a
