FROM rocker/r-ver:4.3

ENV VERSION="0.3"

LABEL base_image="rocker/verse:4.3"
LABEL version="0.3"
LABEL about.summary="r visualization packages"
LABEL about.license="SPDX:Apache-2.0"
LABEL about.tags="r, visualization"
LABEL about.home="https://cran.r-project.org/web/packages/chromoMap/, https://cran.r-project.org/web/packages/ggplot2/, https://cran.r-project.org/web/packages/plotly/"
LABEL software="r_chromoMap"
LABEL software.version="4.1.1"

LABEL maintainer="MGnify team https://www.ebi.ac.uk/support/metagenomics"

RUN apt update && apt install libcurl4-openssl-dev libssl-dev procps pandoc -y

RUN Rscript -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages('plotly', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages('chromoMap', version = '$VERSION', repos = 'http://cran.us.r-project.org')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds
