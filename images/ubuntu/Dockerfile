FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ca-certificates amazon-ecr-credential-helper && apt-get purge && apt-get clean
