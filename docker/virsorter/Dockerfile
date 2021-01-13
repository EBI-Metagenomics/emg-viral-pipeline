FROM continuumio/miniconda3

LABEL base_image="continuumio/miniconda3"
LABEL version="1"
LABEL about.summary="VirSorter: mining viral signal from microbial genomic data"
LABEL about.license="SPDX:GPL-2.0-only"
LABEL about.tags="virus"
LABEL about.home="https://github.com/simroux/VirSorter"
LABEL software="VirSorter"
LABEL software.version="1.0.6"

ENV VERSION 1.0.6

RUN conda install -c bioconda --yes --freeze-installed \
    perl-bioperl-core=1.007002 virsorter=$VERSION && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete

ENV PATH=/opt/conda/bin:${PATH}
ENV PERL5LIB=/opt/conda/lib/perl5/site_perl/5.22.0/:${PERL5LIB}
