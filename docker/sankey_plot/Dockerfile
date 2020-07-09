FROM rocker/r-ver:latest
ENV VERSION 0.12.3
ENV TOOL sankeyD3

LABEL base_image="rocker/verse:latest"
LABEL version="1"
LABEL about.summary="D3 JavaScript Sankey Graphs from R"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="visualization"
LABEL about.home="https://github.com/fbreitwieser/sankeyD3/"
LABEL software="sankeyD3"
LABEL software.version="0.12.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt update && apt install -y procps wget gzip && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN R -e "install.packages('devtools', dependencies=TRUE, repos = 'http://cran.us.r-project.org')"
RUN R -e 'devtools::install_github("fbreitwieser/sankeyD3")'
