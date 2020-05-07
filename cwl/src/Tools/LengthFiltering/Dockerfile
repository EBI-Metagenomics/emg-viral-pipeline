FROM python:2.7.10

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

RUN pip install --upgrade pip
RUN pip install -q biopython
##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             filter_contigs_len.py
# Software Version:     1.0.0
# Description:          Script generates filter_contigs.fasta
##############################################################
COPY . /

CMD ["python", "/filter_contigs_len.py"]
