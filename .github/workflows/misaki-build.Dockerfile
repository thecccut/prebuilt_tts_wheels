FROM python:3.9-slim

ARG PYTHON_VERSION
ARG PACKAGE_VERSION

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && python -m pip install --upgrade pip setuptools wheel

# Set up build environment
WORKDIR /build
RUN mkdir -p /wheelhouse

# Build wheel with all extras (including dependencies)
RUN pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh]==${PACKAGE_VERSION}"

# Set output directory
WORKDIR /wheelhouse
