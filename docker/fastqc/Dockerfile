FROM openjdk:16-slim

LABEL base_image="openjdk:16-jdk"
LABEL version="1" 
LABEL about.summary="A quality control tool for high throughput sequence data."
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="java, visualization"
LABEL about.home="https://www.bioinformatics.babraham.ac.uk/projects/fastqc/"
LABEL software="fastqc"
LABEL software.version="0.11.9"

ENV VERSION 0.11.9

ENV TOOL fastqc

RUN apt-get update && apt-get -y install perl curl unzip && rm -rf /var/lib/apt/lists/*

RUN curl https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v$VERSION.zip -L -o fastqc.zip && \
    unzip fastqc.zip && \
    chmod +x /FastQC/fastqc

ENV PATH="${PATH}:/FastQC/"
