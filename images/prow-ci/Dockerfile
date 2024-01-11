FROM gcr.io/kaniko-project/executor:latest AS kaniko
FROM ubuntu:18.04

LABEL base="ubuntu:18.04"
LABEL description="The base image of Prow CI."

ENV SYSTEM_VERSION "ubuntu:18.04"

ARG GITHUB_USER
ARG GITHUB_PASSWORD

ENV GITHUB_USER=$GITHUB_USER
ENV GITHUB_PASSWORD=$GITHUB_PASSWORD

# git
COPY ./library/.gitconfig /root/.gitconfig
COPY ./library/.gemrc /root/.gemrc

# prowjob & awscliv2
COPY ./library/install.sh install.sh
RUN bash install.sh && rm install.sh

# golang
ENV PATH $PATH:/usr/local/go/bin
ENV GOPATH=$HOME/go
ENV PATH=$PATH:$GOPATH/bin

# scripts
# COPY ./opt /tmp/opt
# RUN chmod -R +x /tmp/opt/* \
#  && ls /tmp/opt | xargs -I {} bash -c 'mv /tmp/opt/{}/* /usr/bin/'

# kaniko
COPY --from=kaniko /kaniko/* /kaniko/

# kaniko env: SSL_CERT_DIR will crash install.sh
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json
ENV PATH /kaniko/:/opt/bin:$PATH:/bin

RUN echo "https://${GITHUB_USER}:${GITHUB_PASSWORD}@github.com" > ~/.git-credentials
ENV GONOSUMDB github.com
ENV GOPRIVATE github.com
COPY ./library/prow /bin/prow
RUN chmod +x /bin/prow
ENV LC_CTYPE en_US.UTF-8
RUN ln -fs /bin/bash /bin/sh # 切换sh为bash

WORKDIR /workspace/src
