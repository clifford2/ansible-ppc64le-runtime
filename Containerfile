# Based on https://github.com/ansible/creator-ee

# Builds devtools base image "creator-base" which pre-installs python and all
# binary dependencies. This makes each derived image much faster to build, even
# when using QEMU emulation.

# ARG EE_BASE_IMAGE=quay.io/fedora/fedora:latest
ARG EE_BASE_IMAGE=quay.io/fedora/fedora:36
FROM $EE_BASE_IMAGE AS base
USER root

RUN \
  dnf update -y && \
  dnf -y upgrade && \
  dnf install -y \
    git \
    podman \
    python3-cffi \
    python3-cryptography \
    python3-pip \
    python3-pyrsistent \
    python3-pyyaml \
    python3-ruamel-yaml \
    python3-wheel \
  && dnf autoremove \
  && pip3 install -U pip setuptools

# These steps are necesssary for ppc64le, for Python packages for which pre-built wheels aren't available
RUN \
  dnf install -y \
    libsodium bcrypt python3-bcrypt \
    make gcc python3-devel libsodium-devel \
  && SODIUM_INSTALL=system pip3 install pynacl \
  && dnf remove -y make gcc python3-devel libsodium-devel \
  && dnf autoremove


# Overly simplified single stage build process: we take all binary dependencies
# using dnf and use pip to install the rest.

#ARG EE_BASE_IMAGE=quay.io/ansible/creator-base:latest
#FROM $EE_BASE_IMAGE
FROM base AS creator
USER root

COPY requirements.in /tmp/requirements.in
#COPY requirements.txt /tmp/requirements.txt
# RUN pip3 install -r /tmp/requirements.in -c /tmp/requirements.txt
RUN \
  pip3 install -r /tmp/requirements.in && \
  rm -rf $(pip3 cache dir)
# Add some collections
COPY requirements.yml /tmp/requirements.yml
ARG AZUL_INVENTORY_VERSION=1.0.6
COPY azul-inventory-${AZUL_INVENTORY_VERSION}.tar.gz /tmp/azul-inventory.tar.gz
RUN /usr/local/bin/ansible-galaxy collection install -r /tmp/requirements.yml
# Set working environment
RUN mkdir -p /runner/{project,artifacts,env,inventory}
WORKDIR /runner
# Add some helpful CLI commands to check we do not remove them inadvertently and output some helpful version information at build time.
RUN set -ex \
  && ansible-lint --version \
  && molecule --version \
  && molecule drivers \
  && podman --version \
  && python3 --version \
  && git --version \
  && uname -a
