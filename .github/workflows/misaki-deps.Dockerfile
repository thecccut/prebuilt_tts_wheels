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

# Debugging: Print CMake version and environment variables
RUN cmake --version
RUN env

# Install pip-tools for dependency resolution
RUN pip install pip-tools

# First, download and build misaki with all its dependencies
RUN pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh]==${PACKAGE_VERSION}"

# Now, instead of discarding dependencies, keep them all
RUN find /wheelhouse -type f -name "*.whl" | sort > /wheelhouse/wheel_list.txt

# Set output directory
WORKDIR /wheelhouse