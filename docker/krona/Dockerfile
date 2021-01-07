FROM continuumio/miniconda3
ENV VERSION 2.7.1

LABEL base_image="continuumio/miniconda3"
LABEL version="1"
LABEL software="krona"
LABEL software.version="2.7.1"
LABEL about.summary="Krona Tools is a set of scripts to create Krona charts from several Bioinformatics tools as well as from text and XML files."
LABEL about.home="https://github.com/marbl/Krona"
LABEL about.documentation="https://github.com/marbl/Krona/wiki"
LABEL about.license_file="https://github.com/marbl/Krona/blob/master/KronaTools/LICENSE.txt"
LABEL about.license="BSD"
LABEL about.tags="visualization, taxonomy"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt-get update && \
    apt install -y procps curl make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN conda install -c bioconda --yes --freeze-installed \
    krona=$VERSION && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete

# setup taxonomic index
RUN cd /opt/conda/opt/krona && bash updateTaxonomy.sh
