FROM python:3.10-slim-bullseye

ARG PYTHON_VERSION
ARG PACKAGE_VERSION
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

# Install build dependencies (using Debian's package for CMake)
RUN apt-get update && apt-get install -y \
    build-essential \
    g++-10 \
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
ENV PATH="/root/.cargo/bin:${PATH}"

# Install maturin, numpy and Cython for building dependencies
RUN pip install maturin numpy Cython

# Force use of older GCC for building wheels
ENV CC=gcc-10 CXX=g++-10

# Build misaki and all its dependencies in one go
# Note: We need to source the cargo env file in the same command
RUN if [ -z "$PACKAGE_VERSION" ]; then echo "PACKAGE_VERSION is required" && exit 1; fi && \
    . $HOME/.cargo/env && \
    pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh,vi]==${PACKAGE_VERSION}"

# Set output directory
WORKDIR /wheelhouse
