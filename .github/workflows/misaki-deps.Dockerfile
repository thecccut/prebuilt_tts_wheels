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

# Install pip-tools and maturin for dependency resolution and Rust package building
RUN pip install pip-tools maturin

# Set CMake policy version to fix pyopenjtalk build issue
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

# First, download and build misaki with all its dependencies
# Try to install pyopenjtalk first with the environment variable set
RUN pip wheel --wheel-dir /wheelhouse pyopenjtalk==0.4.0 || echo "Pyopenjtalk wheel build failed, will try with full misaki install"

# Install underthesea-core with maturin explicitly
RUN pip wheel --wheel-dir /wheelhouse underthesea-core==1.0.4 || echo "underthesea-core wheel build failed, will try with full misaki install"

# Full misaki build with all dependencies
RUN pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh,vi]==${PACKAGE_VERSION}"

# Now, instead of discarding dependencies, keep them all
RUN find /wheelhouse -type f -name "*.whl" | sort > /wheelhouse/wheel_list.txt

# Set output directory
WORKDIR /wheelhouse