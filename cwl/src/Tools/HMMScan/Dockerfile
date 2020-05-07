FROM centos:centos7

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

RUN yum -y update; yum clean all
RUN yum -y install gcc git make wget; yum clean all
RUN wget http://eddylab.org/software/hmmer/hmmer.tar.gz && tar -zxvf hmmer.tar.gz && cd hmmer-* && ./configure && make && make install

RUN wget -nH -P vpHMM_database ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/vpHMM_database.tar.gz && tar -zxvf vpHMM_database/vpHMM_database.tar.gz


CMD ["hmmscan"]
