FROM rocker/r-ver:3.4.4
MAINTAINER kates@ebi.ac.uk


RUN R -e "options(repos = \
  list(CRAN = 'http://mran.revolutionanalytics.com/snapshot/2019-01-06/')); \
  install.packages('ggplot2'); \
  install.packages('optparse'); \ 
  install.packages('gggenes'); \ 
  install.packages('RColorBrewer'); \
"
ADD Make_viral_contig_map.R /
CMD ['Rscript', '/Make_viral_contig_map.R']