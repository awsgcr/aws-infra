FROM alpine:3.10.3

ARG HELM_VERSION
ENV HELM_VERSION ${HELM_VERSION:-v3.1.1}
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz

ARG KUBECTL
ENV KUBECTL ${KUBECTL:-v1.17.3}

# helm & kubectl
RUN set -ex \
  && apk add --no-cache curl ca-certificates jq git bash \
  && curl -o /tmp/${FILENAME} https://get.helm.sh/${FILENAME} \
  && curl -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin/kubectl \
  && rm -rf /tmp/*

# awscli
RUN set -ex \
  && apk add --no-cache python \
  && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
  && unzip awscli-bundle.zip \
  && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
  && rm -rf awscli-bundle.zip \
  && rm -rf ./awscli-bundle

# yq
RUN wget -O yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 \
  && chmod +x yq \
  && mv yq /bin

RUN helm plugin install https://github.com/hypnoglow/helm-s3.git --version 0.9.2

LABEL description="Kubectl, Helm and aws-cli"
LABEL base="alpine"
