FROM rocker/r-ver:3.4.4

LABEL base_image="rocker/verse:3.5.0"
LABEL version="1" 
LABEL about.summary="r visualization packages"
LABEL about.license="SPDX:Apache-2.0"
LABEL about.tags="r, visualization"

RUN apt update && apt install -y procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN R -e "options(repos = \
  list(CRAN = 'http://mran.revolutionanalytics.com/snapshot/2019-01-06/')); \
  install.packages('ggplot2'); \
  install.packages('optparse'); \ 
  install.packages('gggenes'); \ 
  install.packages('RColorBrewer'); \
"
#ADD Make_viral_contig_map.R /
#CMD ['Rscript', '/Make_viral_contig_map.R']
