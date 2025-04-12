ARG PYTHON_VERSION=3.10
ARG PACKAGE_VERSION
ARG LANGUAGE=all
ARG GPU_SUPPORT=cpu

FROM python:${PYTHON_VERSION}-slim-bullseye

# Make sure build arguments are available in the build environment
ARG PACKAGE_VERSION
ARG LANGUAGE
ARG GPU_SUPPORT
ENV PACKAGE_VERSION=${PACKAGE_VERSION}
ENV LANGUAGE=${LANGUAGE}
ENV GPU_SUPPORT=${GPU_SUPPORT}

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

# Conditionally install GPU dependencies or exclude them
RUN if [ "$GPU_SUPPORT" = "gpu" ]; then \
      echo "Building with GPU support - including CUDA dependencies" && \
      pip install --no-cache-dir torch ; \
    else \
      echo "Building CPU-only version - excluding CUDA dependencies" && \
      pip install --no-cache-dir torch --extra-index-url https://download.pytorch.org/whl/cpu ; \
    fi

# Build misaki and dependencies based on selected language
# Note: We need to source the cargo env file in the same command
RUN if [ -z "$PACKAGE_VERSION" ]; then echo "PACKAGE_VERSION is required" && exit 1; fi && \
    . $HOME/.cargo/env && \
    pip wheel --wheel-dir /wheelhouse mojimoji && \
    if [ "$LANGUAGE" = "all" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[en,ja,ko,zh,vi]==$PACKAGE_VERSION; \
    elif [ "$LANGUAGE" = "en" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[en]==$PACKAGE_VERSION; \
    elif [ "$LANGUAGE" = "ja" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[ja]==$PACKAGE_VERSION; \
    elif [ "$LANGUAGE" = "ko" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[ko]==$PACKAGE_VERSION; \
    elif [ "$LANGUAGE" = "zh" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[zh]==$PACKAGE_VERSION; \
    elif [ "$LANGUAGE" = "vi" ]; then \
        pip wheel --wheel-dir /wheelhouse misaki[vi]==$PACKAGE_VERSION; \
    else \
        echo "Unsupported language: $LANGUAGE" && exit 1; \
    fi

# List all wheels for debugging
RUN find /wheelhouse -type f -name "*.whl" | sort > /wheelhouse/wheel_list.txt

# Set output directory
WORKDIR /wheelhouse
