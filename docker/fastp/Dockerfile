FROM debian:buster-slim as build

RUN apt update && apt install --assume-yes --no-install-recommends \
    build-essential git zlib1g-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --branch 'v0.20.1' --depth 1 https://github.com/OpenGene/fastp.git

RUN cd fastp && mkdir bin && make && make install PREFIX=/fastp

FROM debian:buster-slim  

ENV VERSION 0.20.1

LABEL base_image="debian-buster/slim"
LABEL version="1"
LABEL about.summary="A tool designed to provide fast all-in-one preprocessing for FastQ files."
LABEL about.license="https://github.com/OpenGene/fastp/blob/master/LICENSE"
LABEL about.tags="fasta fastq qc"
LABEL about.home="https://github.com/OpenGene/fastp"
LABEL software="fastp"
LABEL software.version="v0.20.1"

RUN mkdir -p /fastp/bin

COPY --from=build /fastp/bin /fastp/bin

ENV PATH="/fastp/bin:${PATH}"