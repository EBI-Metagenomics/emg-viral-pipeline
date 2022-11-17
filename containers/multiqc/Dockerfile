FROM quay.io/microbiome-informatics/miniconda:4.12.0

LABEL base_image="microbiome-informatics/miniconda:4.12.0"
LABEL version="1" 
LABEL about.summary="MultiQC is a tool to create a single report with interactive plots for multiple bioinformatics analyses across many samples."
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="python, visualization"
LABEL about.home="https://multiqc.info/"
LABEL software="multiqc"
LABEL software.version="1.9"

ENV VERSION 1.9

ENV TOOL multiqc

RUN conda install -y multiqc==$VERSION
