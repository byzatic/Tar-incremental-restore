#FROM bash:5.2.15 as bash-base
#FROM bash:alpine3.18 as bash-base
FROM ubuntu:22.04 as bash-base

# install tools


##
FROM bash-base as bash-app

#
COPY . /app
WORKDIR /app

# create catalogs
RUN mkdir -p /backup_output \
  && mkdir -p /backup_source

#
#CMD chmod a+x ./run_in_docker.sh && /usr/local/bin/bash ./run_in_docker.sh
CMD chmod a+x ./run_in_docker.sh && /bin/bash ./run_in_docker.sh
