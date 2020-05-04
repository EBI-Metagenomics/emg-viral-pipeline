FROM python:3

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

RUN pip install --upgrade pip
RUN pip install -q biopython pandas
##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             parse_viral_pred.py
# Software Version:     1.0.0
# Description:          script generates three output_files: High_confidence.fasta, Low_confidence.fasta, Prophages.fasta
##############################################################
COPY . /

CMD ["python", "/parse_viral_pred.py"]
