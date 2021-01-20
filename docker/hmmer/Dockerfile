FROM alpine:3.7

LABEL base_image="alpine:3.7"
LABEL version="1"
LABEL about.summary="HMMER EBI Metagenomics"
LABEL about.license="https://github.com/EddyRivasLab/hmmer/blob/master/LICENSE"
LABEL about.tags="hidden markov chains"
LABEL about.home="http://hmmer.org/"
LABEL software="HMMER"
LABEL software.version="3.1b2"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

ENV VERSION=3.1b2

RUN apk add --no-cache bash wget build-base

RUN wget http://eddylab.org/software/hmmer/hmmer-$VERSION.tar.gz \
   && tar -zxvf hmmer-$VERSION.tar.gz \
   && cd hmmer-$VERSION \
   && ./configure && make && make install

RUN mkdir /scripts

COPY hmmscan_wrapper.sh /scripts

RUN chmod +x /scripts/hmmscan_wrapper.sh

ENV PATH="/hmmer-$VERSION:/scripts:${PATH}"

CMD ["bash"]