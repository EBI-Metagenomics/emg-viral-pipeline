FROM python:3

LABEL maintainer="Ekaterina Sakharova <kates@ebi.ac.uk>"

ADD Additional_data_vpHMMs.xlsx /
RUN pip install --upgrade pip
RUN pip install -q pandas xlrd
##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             Ratio_evalue_table.py
# Software Version:     1.0.0
# Description:          Generates tabular file (File_informative_ViPhOG.tsv) listing results per protein, which include the ratio of the aligned target profile and the abs value of the total Evalue
##############################################################
COPY . /


CMD ["python", "/Ratio_evalue_table.py"]
