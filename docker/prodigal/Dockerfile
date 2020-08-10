FROM alpine:3.7 as build

LABEL base_image="alpine:3.7"
LABEL version="1" 
LABEL about.summary="Protein-coding gene prediction for prokaryotic genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="gene-caller"
LABEL about.home="https://github.com/hyattpd/Prodigal"
LABEL software="prodigal"
LABEL software.version="2.6.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apk add --no-cache git build-base zlib-dev

RUN git clone --depth 1 --branch 'v2.6.3' https://github.com/hyattpd/Prodigal.git && \
    cd Prodigal && make install

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

COPY --from=build /Prodigal /Prodigal

RUN apk add --no-cache bash

ENV PATH="/Prodigal:${PATH}"

CMD ["prodigal"]