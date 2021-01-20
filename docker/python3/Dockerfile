FROM python:3-slim

LABEL base_image="python:3-slim"
LABEL version="1"
LABEL about.summary="Base python image with required tools for EBI Metagenomics"
LABEL about.license="SPDX:PSF-2.0"
LABEL about.tags="python"
LABEL about.home="https://www.python.org"
LABEL software="python"
LABEL software.version="3"

LABEL maintainer="MGnify team <https://www.ebi.ac.uk/support/metagenomics>"

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python"]