FROM continuumio/miniconda3
ENV VERSION 0.20.0

RUN apt update && apt install -y procps && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda config --add channels conda-forge && \
		conda config --add channels bioconda && \
		conda config --add channels default

RUN conda install -c bioconda fastp=$VERSION && conda clean -a