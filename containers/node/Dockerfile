FROM ubuntu:16.04

ARG NODE_ALIAS
ARG NODE_SERVER_PORT
ARG NODE_CLIENT_PORT
ARG NETWORK_NAME

# Setup dependencies

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
RUN bash -c 'echo "deb https://repo.sovrin.org/deb xenial stable" >> /etc/apt/sources.list'
RUN apt update || true
RUN apt install -y apt-transport-https
RUN apt update
RUN apt install -y indy-node


# Configure node
RUN sed -i "s/NETWORK_NAME = None/NETWORK_NAME = '$NETWORK_NAME'/g" /etc/indy/indy_config.py