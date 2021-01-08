FROM ubuntu:20.04

LABEL base_image="ubuntu/20.04"
LABEL version="1"
LABEL about.summary="EMG Viral Pipeline basic tools."
LABEL about.license="SPDX:GPL-3.0-or-later"
LABEL about.tags="unix, python"
LABEL about.home="https://github.com/EBI-Metagenomics/emg-viral-pipeline/"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

RUN apt update && \
    apt install -y --no-install-recommends procps wget curl tar gzip python3 pdftk-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
