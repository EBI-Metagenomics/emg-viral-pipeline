FROM rocker/r-ver:3.4.4

RUN apt update && apt install -y procps && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN R -e "options(repos = \
  list(CRAN = 'http://mran.revolutionanalytics.com/snapshot/2019-01-06/')); \
  install.packages('ggplot2'); \
  install.packages('optparse'); \ 
  install.packages('gggenes'); \ 
  install.packages('RColorBrewer'); \
"
#ADD Make_viral_contig_map.R /
#CMD ['Rscript', '/Make_viral_contig_map.R']