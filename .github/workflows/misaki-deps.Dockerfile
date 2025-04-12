ARG PYTHON_VERSION=3.10
ARG PACKAGE_VERSION

FROM python:${PYTHON_VERSION}-slim-bullseye

# Make sure PACKAGE_VERSION is available in the build environment
ARG PACKAGE_VERSION
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

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
ENV PYTHONPATH=/usr/local/lib/python3.10/site-packages
ENV PIP_NO_BUILD_ISOLATION=0
ENV PATH="/root/.cargo/bin:${PATH}"

# Install maturin, numpy and Cython for building dependencies
RUN pip install maturin numpy Cython

# Build misaki and all its dependencies in one go
# Note: We need to source the cargo env file in the same command
RUN if [ -z "$PACKAGE_VERSION" ]; then echo "PACKAGE_VERSION is required" && exit 1; fi && \
    . $HOME/.cargo/env && \
    pip wheel --wheel-dir /wheelhouse mojimoji && \
    pip wheel --wheel-dir /wheelhouse misaki[en,ja,ko,zh,vi]==$PACKAGE_VERSION

# List all wheels for debugging
RUN find /wheelhouse -type f -name "*.whl" | sort > /wheelhouse/wheel_list.txt

# Set output directory
WORKDIR /wheelhouse
