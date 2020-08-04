FROM ubuntu:bionic

ENV VERSION 1.1
ENV TOOL PPRMETA

LABEL base_image="continuumio/miniconda3"
LABEL version="1" 
LABEL about.summary="PPR-Meta a tool for identifying phages and plasmids from metagenomic fragments using deep learning"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="python, phage, virus, deeplearning"
LABEL about.home="https://github.com/deprekate/PHANOTATE"
LABEL software="PPR-Meta"
LABEL software.version="1.1"
LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt-get update && \
    apt-get install -y python2.7 python-pip git unzip wget libxt6 && \    
    wget https://github.com/zhenchengfang/PPR-Meta/archive/v1.1.tar.gz && \
    tar -xzf v1.1.tar.gz && \
    rm v1.1.tar.gz && \
    pip install -U numpy h5py tensorflow keras==2.0.8 --no-cache-dir  && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /mcr-install

RUN mkdir /opt/mcr && \
    wget http://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/glnxa64/MCR_R2018a_glnxa64_installer.zip && \
    unzip -q MCR_R2018a_glnxa64_installer.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /mcr-install

RUN chmod +x /PPR-Meta-1.1/PPR_Meta

ENV LD_LIBRARY_PATH=/opt/mcr/v94/runtime/glnxa64:/opt/mcr/v94/bin/glnxa64:/opt/mcr/v94/sys/os/glnxa64:/opt/mcr/v94/extern/bin/glnxa64

# this script is wrapper
# used by the CWL implementaion
COPY pprmeta.sh /PPR-Meta-1.1/

ENV PATH=/PPR-Meta-1.1:$PATH