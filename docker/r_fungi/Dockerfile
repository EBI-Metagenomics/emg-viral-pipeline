FROM rocker/r-ver:3.5.0

LABEL base_image="rocker/verse:3.5.0"
LABEL version="1" 
LABEL about.summary="r visualization packages"
LABEL about.license="SPDX:Apache-2.0"
LABEL about.tags="r, visualization"
LABEL about.home="https://cran.r-project.org/web/packages/chromoMap/, https://cran.r-project.org/web/packages/ggplot2/, https://cran.r-project.org/web/packages/plotly/"
LABEL software="r packages chromoMap, ggplot2, plotly"
LABEL software.version="3.15"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN Rscript -e "install.packages('chromoMap', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')" && \ 
    Rscript -e "install.packages('plotly', repos = 'http://cran.us.r-project.org')" && \  
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds
