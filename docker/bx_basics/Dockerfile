FROM ubuntu:xenial
ENV VERSION 1.0

RUN apt update && apt install -y procps wget curl tar gzip python3 pdftk && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*