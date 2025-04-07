FROM python:3.9-slim

ARG PYTHON_VERSION
ARG PACKAGE_VERSION

# Install build dependencies (using Debian's package for CMake)
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    gnupg \
    lsb-release \
    cmake \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && python -m pip install --upgrade pip setuptools wheel

# Set up build environment
WORKDIR /build
RUN mkdir -p /wheelhouse

# Set environment variables for build
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5
ENV PYTHONPATH=/usr/local/lib/python3.9/site-packages
ENV PIP_NO_BUILD_ISOLATION=0

# Install maturin for Rust package building
RUN pip install maturin

# Build misaki and all its dependencies in one go
RUN pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh,vi]==${PACKAGE_VERSION}"

# Set output directory
WORKDIR /wheelhouse
