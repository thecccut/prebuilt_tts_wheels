ARG PYTHON_VERSION
FROM --platform=$TARGETPLATFORM python:${PYTHON_VERSION}-slim

ARG PACKAGE_VERSION
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Python build dependencies
RUN python -m pip install --upgrade pip setuptools wheel maturin

# Create and set working directory
WORKDIR /build

# Build the wheel
RUN mkdir -p wheelhouse
CMD pip wheel --no-deps --wheel-dir /wheelhouse "misaki[en,ja,ko,zh]==${PACKAGE_VERSION}"
