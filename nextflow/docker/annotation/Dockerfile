FROM python:3

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

RUN pip install --upgrade pip
RUN pip install -q biopython pandas
##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             viral_contigs_annotation.py
# Software Version:     1.0.0
# Description:          Script generates tabular output for each viral prediction file which summarizes the ViPhOG annotations for all the corresponding predicted proteins
##############################################################
COPY . /


CMD ["python", "/viral_contigs_annotation.py"]
