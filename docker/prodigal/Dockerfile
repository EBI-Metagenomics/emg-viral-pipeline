FROM alpine:3.7

LABEL base_image="alpine:3.7"
LABEL version="1" 
LABEL about.summary="Protein-coding gene prediction for prokaryotic genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="gene-caller"
LABEL about.home="https://github.com/hyattpd/Prodigal"
LABEL software="prodigal"
LABEL software.version="2.6.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apk add --no-cache bash git build-base zlib-dev

RUN git clone https://github.com/hyattpd/Prodigal.git && \
    cd Prodigal && make install

ENV PATH="/Prodigal:${PATH}"

CMD ["prodigal"]