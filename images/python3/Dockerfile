FROM python:3.11.0

RUN apt update && apt install -y ca-certificates amazon-ecr-credential-helper &&  apt purge && apt clean

COPY ./requirements.txt requirements.txt
RUN pip install --no-cache -r requirements.txt