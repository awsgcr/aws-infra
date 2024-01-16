FROM gcr.io/kaniko-project/executor:latest AS kaniko
FROM ubuntu:18.04

LABEL base="ubuntu:18.04"
LABEL description="The base image of Prow CI, Docker in Docker Using DinD."

ENV SYSTEM_VERSION "ubuntu:18.04"

ARG GITHUB_USER
ARG GITHUB_PASSWORD

ENV GITHUB_USER=$GITHUB_USER
ENV GITHUB_PASSWORD=$GITHUB_PASSWORD

# git
COPY ./library/.gitconfig /root/.gitconfig

# prowjob & awscliv2
COPY ./library/install.sh install.sh
RUN bash install.sh && rm install.sh

# Docker in Docker setup
RUN DPKG_ARCH="$(dpkg --print-architecture)" \
    && distro=$(lsb_release -is | awk '{print tolower($0)}') \
    && mkdir -p /etc/apt/keyrings \
    && ( curl -fsSL https://download.docker.com/linux/${distro}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg ) \
    && version=$(lsb_release -cs | sed 's/bookworm\|n\/a/bullseye/g') \
    && ( echo "deb [arch=${DPKG_ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro} ${version} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null ) \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli --no-install-recommends --allow-unauthenticated

# move Docker storage location
RUN echo 'DOCKER_OPTS="${DOCKER_OPTS} --data-root=/docker-graph"' | \
    tee --append /etc/default/docker
RUN mkdir /docker-graph

COPY ./library/runner.sh /usr/local/bin/

# aws-iam-authenticator and docker-buildx
RUN wget --no-check-certificate "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.3/aws-iam-authenticator_0.5.3_linux_amd64" -O /usr/local/bin/aws-iam-authenticator && chmod +x /usr/local/bin/aws-iam-authenticator \
    && mkdir -p ${DOCKER_BUILDX_PATH} \
    && wget --no-check-certificate "https://github.com/docker/buildx/releases/download/${DOCKER_BUILDX_VERSION}/buildx-${DOCKER_BUILDX_VERSION}.linux-amd64" -O ${DOCKER_BUILDX_PATH}/docker-buildx \
    && chmod +x ${DOCKER_BUILDX_PATH}/docker-buildx

# fix unicode
ENV LANG=C.UTF-8

RUN apt update && apt install dnsutils telnet -y

# golang
ENV PATH $PATH:/usr/local/go/bin
ENV GOPATH=$HOME/go
ENV PATH=$PATH:$GOPATH/bin

# scripts
 COPY ./opt /tmp/opt
 RUN chmod -R +x /tmp/opt/* \
    && ls /tmp/opt | xargs -I {} bash -c 'mv /tmp/opt/{}/* /usr/bin/'

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
RUN ln -fs /bin/bash /bin/sh

WORKDIR /workspace/src
