#! /bin/bash
apt update -y
apt install -y software-properties-common openssh-client ca-certificates markdown wget curl jq coreutils util-linux python zip unzip gawk rpm binutils bc libopenjp2-tools rsync locales
if [[ ${SYSTEM_VERSION} == "ubuntu:18.04" ]]; then
  add-apt-repository -y ppa:git-core/ppa
fi
apt install -y git

# install aws
curl -k "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip &&./aws/install && rm -rf awscliv2.zip && rm -rf ./aws

# update LC
locale-gen en_US.UTF-8
