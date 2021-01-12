FROM ubuntu:latest

LABEL base_image="ubuntu:latest"
LABEL version="1" 
LABEL about.summary="MashMap implements a fast and approximate algorithm for computing local alignment boundaries between long DNA sequences"
LABEL about.license="https://github.com/marbl/MashMap/blob/master/LICENSE.txt"
LABEL about.tags="alignment"
LABEL about.home="https://github.com/marbl/MashMap"
LABEL software="mashmap"
LABEL software.version="2.0"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

ENV TARBALL https://github.com/marbl/MashMap/releases/download/v2.0/mashmap-Linux64-v2.0.tar.gz


RUN apt update && \
    apt install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L $TARBALL | tar xvz && \
    chmod +x /mashmap-Linux64-v2.0/mashmap

ENV PATH="/mashmap-Linux64-v2.0:${PATH}"