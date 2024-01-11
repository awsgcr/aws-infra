FROM gcr.io/kaniko-project/executor:latest AS kaniko
FROM ubuntu:18.04

LABEL base="ubuntu:18.04"
LABEL description="The base image of AWS Cli V2."

# install awscliv2
COPY ./library/install.sh install.sh
RUN bash install.sh && rm install.sh
