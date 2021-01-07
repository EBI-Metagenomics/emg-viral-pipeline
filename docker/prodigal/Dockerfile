FROM ubuntu:latest as build

LABEL base_image="ubuntu:latest"
LABEL version="1" 
LABEL about.summary="Protein-coding gene prediction for prokaryotic genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="gene-caller"
LABEL about.home="https://github.com/hyattpd/Prodigal"
LABEL software="prodigal"
LABEL software.version="2.6.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt-get update && apt install wget build-essential zlib1g-dev unzip -y

RUN wget https://github.com/hyattpd/Prodigal/archive/v2.6.3.zip && \
    unzip v2.6.3.zip && \
    cd Prodigal-2.6.3 && make install

FROM ubuntu:latest

LABEL base_image="ubuntu:latest"
LABEL version="1" 
LABEL about.summary="Protein-coding gene prediction for prokaryotic genomes"
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="gene-caller"
LABEL about.home="https://github.com/hyattpd/Prodigal"
LABEL software="prodigal"
LABEL software.version="2.6.3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

COPY --from=build /Prodigal-2.6.3 /Prodigal

ENV PATH="/Prodigal:${PATH}"

CMD ["prodigal"]