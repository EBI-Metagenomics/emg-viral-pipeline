FROM python:3

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

RUN pip install --upgrade pip
RUN pip install -q pandas biopython ete3
RUN python -c 'from ete3 import NCBITaxa; NCBITaxa()'
##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             contig_taxonomic_assign.py
# Software Version:     1.0.0
##############################################################
COPY . /


CMD ["python", "/contig_taxonomic_assign.py"]
