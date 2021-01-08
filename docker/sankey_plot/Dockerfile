FROM rocker/r-ver:latest

ENV VERSION 0.12.3
ENV TOOL sankeyD3

LABEL base_image="rocker/r-ver:latest"
LABEL version="1"
LABEL about.summary="D3 JavaScript Sankey Graphs from R"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="visualization"
LABEL about.home="https://github.com/fbreitwieser/sankeyD3/"
LABEL software="sankeyD3"
LABEL software.version="v0.12.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN R -e "install.packages('devtools')"

RUN R -e 'devtools::install_github("fbreitwieser/sankeyD3")'

RUN apt-get update && apt install -y --no-install-recommends pandoc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
