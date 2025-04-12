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

# Install all build dependencies including those needed for Japanese (MeCab) and Vietnamese support
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    gnupg \
    lsb-release \
    cmake \
    wget \
    ffmpeg \
    libsndfile1-dev \
    # Dependencies for MeCab and Japanese support
    mecab \
    mecab-ipadic \
    mecab-ipadic-utf8 \
    libmecab-dev \
    swig \
    # Dependencies for espeak-ng (needed by phonemizer)
    espeak-ng \
    espeak-ng-data \
    # Additional build dependencies
    pkg-config \
    libssl-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/share/espeak-ng-data \
    && ln -s /usr/lib/*/espeak-ng-data/* /usr/share/espeak-ng-data/ \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && python -m pip install --upgrade pip setuptools wheel

# Set environment variables for build
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5
ENV PYTHONPATH=/usr/local/lib/python${PYTHON_VERSION}/site-packages
ENV PIP_NO_BUILD_ISOLATION=0
ENV PATH="/root/.cargo/bin:${PATH}"
ENV PHONEMIZER_ESPEAK_PATH=/usr/bin/espeak-ng
ENV ESPEAK_DATA_PATH=/usr/share/espeak-ng-data

# Set up build environment
WORKDIR /build
RUN mkdir -p /wheelhouse

# Install maturin, numpy and Cython for building dependencies
RUN pip install maturin numpy Cython

# Conditionally install GPU dependencies or exclude them
RUN if [ "$GPU_SUPPORT" = "gpu" ]; then \
      echo "Building with GPU support - including CUDA dependencies" && \
      pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu124 ; \
    else \
      echo "Building CPU-only version - excluding CUDA dependencies" && \
      pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu ; \
    fi

# Build Japanese dependencies - using exact package names from Misaki dependencies
RUN pip wheel --wheel-dir /wheelhouse \
    fugashi==1.3.0 \
    unidic-lite==1.0.8 \
    jaconv==0.3.4 \
    mojimoji==0.0.13 \
    && pip wheel --wheel-dir /wheelhouse unidic || echo "unidic build failed - will be installed during full build" \
    && pip wheel --wheel-dir /wheelhouse pyopenjtalk || echo "pyopenjtalk build failed - will be installed during full build"

# Build English dependencies
RUN pip wheel --wheel-dir /wheelhouse \
    num2words \
    spacy \
    spacy-curated-transformers \
    phonemizer-fork>=3.3.2 \
    espeakng-loader==0.2.4

# Build Korean dependencies (for 'ko' or 'all')
RUN if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "ko" ]; then \
      pip wheel --wheel-dir /wheelhouse jamo nltk; \
    fi

# Build Chinese dependencies (for 'zh' or 'all')
RUN if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "zh" ]; then \
      pip wheel --wheel-dir /wheelhouse jieba ordered-set pypinyin cn2an pypinyin-dict; \
    fi

# Build Vietnamese dependencies (for 'vi' or 'all')
RUN if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "vi" ]; then \
      pip wheel --wheel-dir /wheelhouse underthesea-core==1.0.4 underthesea || echo "underthesea build failed - will be installed during full build"; \
    fi

# Build Hebrew dependencies if needed (for 'he' or 'all')
RUN if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "he" ]; then \
      pip wheel --wheel-dir /wheelhouse "mishkal-hebrew>=0.3.2" || echo "mishkal-hebrew build failed - will be installed during full build"; \
    fi

# Build kokoro and dependencies based on selected language
# Note: We need to source the cargo env file in the same command
# Kokoro already includes misaki[en] as a dependency
RUN if [ -z "$PACKAGE_VERSION" ]; then echo "PACKAGE_VERSION is required" && exit 1; fi && \
    . $HOME/.cargo/env && \
    if [ "$LANGUAGE" = "all" ]; then \
        # For all-language support, ensure we have all Misaki languages first
        pip wheel --wheel-dir /wheelhouse "misaki[en,ja,ko,zh,vi]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[all]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "en" ]; then \
        # English is included by default in Kokoro's dependencies
        pip wheel --wheel-dir /wheelhouse "kokoro[en]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "ja" ]; then \
        # For non-English languages, we need to ensure Misaki support for that language
        pip wheel --wheel-dir /wheelhouse "misaki[en,ja]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[ja]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "zh" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en,zh]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[zh]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "ko" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en,ko]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[ko]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "vi" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en,vi]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "fr" ]; then \
        # For languages only in Kokoro, just include default Misaki[en]
        pip wheel --wheel-dir /wheelhouse "misaki[en]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[fr]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "de" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[de]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "es" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[es]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "ru" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[ru]==$PACKAGE_VERSION"; \
    elif [ "$LANGUAGE" = "pt" ]; then \
        pip wheel --wheel-dir /wheelhouse "misaki[en]==$PACKAGE_VERSION" && \
        pip wheel --wheel-dir /wheelhouse "kokoro[pt]==$PACKAGE_VERSION"; \
    else \
        echo "Unsupported language: $LANGUAGE" && exit 1; \
    fi

# Download the spaCy model needed for English
RUN pip install -U pip && \
    pip wheel --wheel-dir /wheelhouse "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl" || \
    echo "spaCy model download failed - will be installed in the application container"

# List all wheels for debugging
RUN find /wheelhouse -type f -name "*.whl" | sort > /wheelhouse/wheel_list.txt
RUN echo "Total wheel count: $(cat /wheelhouse/wheel_list.txt | wc -l)"

# Set output directory
WORKDIR /wheelhouse