FROM quay.io/microbiome-informatics/miniconda:4.12.0

LABEL base_image="quay.io/microbiome-informatics/miniconda:4.12.0"

LABEL about.summary="Base python image with required tools for EBI Metagenomics"
LABEL about.license="SPDX:PSF-2.0"
LABEL about.tags="python"
LABEL about.home="https://www.python.org"
LABEL software="virify-python3"
LABEL software.version="1.1"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python"]