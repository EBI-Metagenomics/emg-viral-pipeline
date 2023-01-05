FROM quay.io/microbiome-informatics/miniconda:4.12.0

LABEL base_image="microbiome-informatics/miniconda:4.12.0"
LABEL version="1.1"
LABEL about.summary="CheckV is a fully automated command-line pipeline for assessing the quality of single-contig viral genomes, including identification of host contamination for integrated proviruses, estimating completeness for genome fragments, and identification of closed genomes."
LABEL about.license_file="https://bitbucket.org/berkeleylab/checkv/src/master/LICENSE.txt"
LABEL about.tags="virus quality"
LABEL about.home="https://bitbucket.org/berkeleylab/checkv"
LABEL software="CheckV"
LABEL software.version="0.8.1__1"

ENV VERSION 0.8.1

RUN conda install -c conda-forge -c bioconda --yes --freeze-installed \
    checkv=$VERSION seqtk=1.3 && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete
