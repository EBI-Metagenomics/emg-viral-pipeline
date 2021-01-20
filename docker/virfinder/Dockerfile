FROM rocker/r-ver:latest

LABEL base_image="rocker/r-ver:latest"
LABEL version="1"
LABEL about.summary="VirFinder: R package for identifying viral sequences from metagenomic data using sequence signatures"
LABEL about.license="https://github.com/jessieren/VirFinder/blob/master/licence.md"
LABEL about.tags="virus"
LABEL about.home="https://github.com/jessieren/VirFinder"
LABEL software="VirFinder"
LABEL software.version="1.1#eb8032e"

ENV COMMIT eb8032e 

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

# install dependencies for virsorter
RUN Rscript -e "install.packages('gapminder', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages('glmnet', repos = 'http://cran.us.r-project.org')" && \ 
    Rscript -e "install.packages('Rcpp', repos = 'http://cran.us.r-project.org')" && \ 
    Rscript -e "install.packages('purrr', version = '0.3.2', repos = 'http://cran.us.r-project.org')" && \
    install2.r --error BiocManager \
    && Rscript -e 'requireNamespace("BiocManager"); BiocManager::install();' \
    && Rscript -e 'requireNamespace("BiocManager"); BiocManager::install(c("qvalue"));' \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/jessieren/VirFinder.git && \
    cd VirFinder && git checkout $COMMIT && cd ..

RUN R CMD INSTALL /VirFinder/linux/VirFinder_1.1.tar.gz

RUN mkdir virfinder_exec/ && \
    printf '#!/usr/bin/env Rscript\nlibrary(VirFinder) \n args <- commandArgs(trailingOnly = TRUE) \n filein <- args[1] \n \
            \n predResult <- VF.pred(filein) \n predResult[order(predResult$pvalue),]' > /virfinder_exec/virfinderGO.R && \
    chmod 777 /virfinder_exec/virfinderGO.R

ENV PATH /virfinder_exec/:$PATH

RUN apt-get clean all && apt-get remove -y git && apt-get -y autoremove && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
