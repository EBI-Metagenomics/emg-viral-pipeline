FROM gcc:11 as build

WORKDIR /opt/gt-src

RUN curl -L https://github.com/genometools/genometools/archive/refs/tags/v1.6.2.tar.gz --output v1.6.2.tar.gz && \
    tar -xf v1.6.2.tar.gz

RUN cd genometools-1.6.2 && make install cairo=no useshared=no prefix=/opt/gt/

FROM quay.io/microbiome-informatics/miniconda:4.12.0

LABEL base_image="quay.io/microbiome-informatics/miniconda:4.12.0"

LABEL about.summary="Base python image and related tools with required tools for EBI Metagenomics"
LABEL about.license="SPDX:PSF-2.0"
LABEL about.tags="python"
LABEL about.home="https://www.python.org"
LABEL software="virify-python3"
LABEL software.version="1.2"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

COPY --from=build /opt/gt/ /opt/gt

RUN pip install --no-cache-dir ete3==3.1.1 biopython==1.80 pandas==1.5.2

ENV PATH /opt/gt/bin:$PATH

CMD ["python"]