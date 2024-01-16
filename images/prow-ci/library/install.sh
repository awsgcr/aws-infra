#! /bin/bash
HELM_VERSION=v3.13.3
KUBECTL_VERSION=v1.19.13
CMD_VERSION=1.13.168
SMARTLING_VERSION=v1.6.0-rc13
GO_VERSION=1.20.13
set -e
mkdir -p /tmp/prowjob || true

apt update -y
apt install -y software-properties-common openssh-client ca-certificates markdown wget curl jq coreutils util-linux python zip unzip gawk rpm binutils bc libopenjp2-tools rsync locales
if [[ ${SYSTEM_VERSION} == "ubuntu:18.04" ]]; then
  add-apt-repository -y ppa:git-core/ppa
fi
apt install -y git xxd

# install ripgrep
curl -k -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb
dpkg -i ripgrep_14.1.0-1_amd64.deb

# install hub
wget -O hub.tgz https://github.com/github/hub/releases/download/v2.13.0/hub-linux-amd64-2.13.0.tgz
mkdir /hub
tar -xvf hub.tgz -C /hub --strip-components 1
bash /hub/install
hub --version

# install yq
wget -O yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64
chmod +x yq
mv yq /bin

# install helm & kubectl
FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz
curl -k -o /tmp/${FILENAME} https://get.helm.sh/${FILENAME} \
  && curl -k -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin/kubectl \
  && rm -rf /tmp/*
helm plugin install https://github.com/hypnoglow/helm-s3.git --version 0.16.0

# install kustomize
curl -k -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash
mv kustomize /usr/local/bin

# install aws
curl -k "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip &&./aws/install && rm -rf awscliv2.zip && rm -rf ./aws \
  && aws --version

# install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
  && mv /tmp/eksctl /usr/local/bin \
  && eksctl version

# install jsonnet
curl --silent --location "https://github.com/google/jsonnet/releases/download/v0.17.0/jsonnet-bin-v0.17.0-linux.tar.gz" | tar xz -C /tmp \
  && mv /tmp/jsonnet* /usr/local/bin

# install golang
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
rm -rf go${GO_VERSION}.linux-amd64.tar.gz

# install makisu
go install github.com/uber/makisu/bin/makisu@latest || mv $GOPATH/bin/makisu /bin/ || true

# install docker-credential-ecr-login
go install github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login@latest && mv $GOPATH/bin/docker-credential-ecr-login /bin/ || true

# install buildkit
bash -c "
  cd ~
  wget --no-check-certificate https://github.com/moby/buildkit/releases/download/v0.8.2/buildkit-v0.8.2.linux-amd64.tar.gz
  tar -xzf buildkit-v0.8.2.linux-amd64.tar.gz
  mv bin/* /bin
  rm -rf bin buildkit-v0.8.2.linux-amd64.tar.gz
"

# update LC
locale-gen en_US.UTF-8

# install python libs
apt-get install -y libcairo2 python3-pip || true
python3 -m pip install --upgrade pip || true
python3 -m pip install --upgrade Pillow || true
pip3 install --no-cache-dir --no-compile requests || true
pip3 install --no-cache-dir --no-compile boto3 || true
pip3 install --no-cache-dir --no-compile elasticsearch || true
pip3 install --no-cache-dir --no-compile requests-aws4auth || true
pip3 install --no-cache-dir --no-compile cairosvg || true
pip3 install --no-cache-dir --no-compile yamllint || true
pip3 install --no-cache-dir --no-compile oyaml || true
pip3 install --no-cache-dir --no-compile clickhouse_driver || true
pip3 install --no-cache-dir --no-compile influxdb || true

pip install --no-cache-dir --no-compile requests || true
pip install --no-cache-dir --no-compile clickhouse_driver || true
pip install --no-cache-dir --no-compile boto3 || true
pip install --no-cache-dir --no-compile elasticsearch || true
pip install --no-cache-dir --no-compile requests-aws4auth || true
pip install --no-cache-dir --no-compile yamllint || true
pip install --no-cache-dir --no-compile oyaml || true

# install yamllint
pip install --no-cache-dir --no-compile yamllint

# docker
curl -k -fsSL https://get.docker.com | sh || true

# install node.js
# curl -k -sL https://deb.nodesource.com/setup_12.x | bash -
# apt install -y nodejs
# apt install -y npm
# npm install -g yarn

# install rootlesskit
# bash -c "
#   rm -rf /go/src/github.com/rootless-containers/rootlesskit
#   git clone https://github.com/rootless-containers/rootlesskit.git /go/src/github.com/rootless-containers/rootlesskit
#   cd /go/src/github.com/rootless-containers/rootlesskit
#   git checkout -q v0.11.1  && \
#     CGO_ENABLED=0 go build -o /rootlesskit ./cmd/rootlesskit
#   mv /rootlesskit /bin
#   rm -rf /go/src/github.com/rootless-containers/rootlesskit
#   file /bin/rootlesskit | grep "statically linked"
# "

# install Ruby
# apt install -y rbenv
# rbenv install $(rbenv install -l | grep -v - | tail -1) || true
# gem install yaml

# Clenaup
rm -v hub.tgz
rm -v ripgrep_14.1.0-1_amd64.deb
rm -frv /hub
rm -rf /var/lib/apt/lists/*
rm -rf wrk.zip wrk-master/
