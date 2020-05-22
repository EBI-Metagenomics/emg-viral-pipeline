FROM continuumio/miniconda3
ENV VERSION 2.6.3 
LABEL maintainer="Martin Hoelzer <mhoelzer@ebi.ac.uk>"

RUN apt update && apt install -y procps && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda install -c bioconda prodigal=$VERSION && conda clean -a

CMD ["prodigal"]
