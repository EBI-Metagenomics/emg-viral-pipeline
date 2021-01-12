  
FROM ruby:2.6-slim

ENV VERSION 2.0.1

LABEL base_image="ruby/2.6-slim"
LABEL version="1"
LABEL about.summary="BioRuby is an open source Ruby library for developing bioinformatics software."
LABEL about.license="https://github.com/bioruby/bioruby/blob/2.0.1/LEGAL"
LABEL about.tags="ruby"
LABEL about.home="https://github.com/bioruby/bioruby"
LABEL software="bioruby"
LABEL software.version="v2.0.1"

RUN gem install bio -v $VERSION

ENV PATH="${PATH}:/bioruby"