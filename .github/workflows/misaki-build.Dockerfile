ARG PYTHON_VERSION
FROM --platform=$TARGETPLATFORM python:${PYTHON_VERSION}-slim

ARG PACKAGE_VERSION
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

# Install build dependencies and Rust in one layer to reduce image size
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && python -m pip install --upgrade pip setuptools wheel maturin

# Set up build environment
WORKDIR /build
RUN mkdir -p /wheelhouse

# Source cargo env and build wheel
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["source $HOME/.cargo/env && pip wheel --no-deps --wheel-dir /wheelhouse \"misaki[en,ja,ko,zh]==${PACKAGE_VERSION}\""]
