FROM continuumio/miniconda3
ENV VERSION 1.9
ENV TOOL multiqc

RUN apt update && apt install -y procps wget gzip pigz && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --add channels default

RUN conda install $TOOL=$VERSION && conda clean -a

