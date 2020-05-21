FROM rocker/verse:latest

# install dependencies for virsorter
RUN Rscript -e "install.packages('gapminder', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages('glmnet', repos = 'http://cran.us.r-project.org')" && \ 
    Rscript -e "install.packages('Rcpp', repos = 'http://cran.us.r-project.org')" && \ 
install2.r --error BiocManager \
    && Rscript -e 'requireNamespace("BiocManager"); BiocManager::install();' \
    && Rscript -e 'requireNamespace("BiocManager"); BiocManager::install(c("qvalue"));' \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN apt-get update && apt-get install -y git && git clone https://github.com/jessieren/VirFinder.git
RUN R CMD INSTALL /VirFinder/linux/VirFinder_1.1.tar.gz


RUN mkdir virfinder_exec/ && \
            printf '#!/usr/bin/env Rscript\nlibrary(VirFinder) \n args <- commandArgs(trailingOnly = TRUE) \n filein <- args[1] \n \
            \n predResult <- VF.pred(filein) \n predResult[order(predResult$pvalue),]' > /virfinder_exec/virfinderGO.R && \
    chmod 777 /virfinder_exec/virfinderGO.R

ENV PATH /virfinder_exec/:$PATH

RUN apt-get clean all && apt remove -y git && \
		apt-get purge && \
		rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /scratch

ADD /run_virfinder.Rscript /usr/local/bin/
