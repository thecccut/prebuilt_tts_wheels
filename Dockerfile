# Use Python 3.10 slim as the base image
FROM python:3.10-slim AS final

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies.
# Note: Installing build-essential as a fallback in case uv needs to compile a package
# not found in the pre-built wheels (e.g., if wheelhouse is incomplete or versions mismatch).
# The primary goal is still to use wheels from --find-links for major compiled deps.
# espeak-ng is required at runtime by phonemizer.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # build-essential is a fallback in case uv needs to compile a package.
    build-essential \
    # libstdc++6 should be compatible as base image matches wheel builder.
    libstdc++6 \
    espeak-ng \
    espeak-ng-data \
    libsndfile1 \
    curl \
    ffmpeg \
    jq \
    unzip \
    file \
    # Add MeCab for Japanese language support
    mecab \
    mecab-ipadic \
    mecab-ipadic-utf8 \
    libmecab-dev \
    swig \
 && apt-get clean && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /usr/share/espeak-ng-data \
 && ln -s /usr/lib/*/espeak-ng-data/* /usr/share/espeak-ng-data/

# Install UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/ && \
    mv /root/.local/bin/uvx /usr/local/bin/

# Create non-root user (UID 1000) and app directory
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app/api/src/models/v1_0

WORKDIR /app

# Copy the pre-built wheels from the GHCR image
COPY --from=ghcr.io/remsky/prebuilt_tts_wheels/misaki-deps:0.9.4-py3.10 /wheelhouse /wheelhouse

# Copy dependency definition with proper permissions
COPY --chown=appuser:appuser pyproject.toml ./pyproject.toml

# Set Phonemizer env vars before install
ENV PHONEMIZER_ESPEAK_PATH=/usr/bin/espeak-ng \
    ESPEAK_DATA_PATH=/usr/share/espeak-ng-data

# Create cache directory with correct permissions before installing dependencies
RUN mkdir -p /root/.cache/uv && \
    chmod 777 /root/.cache/uv

# Install dependencies AS ROOT using pre-built wheels where available, falling back to PyPI/build.
# Using --find-links to prioritize local wheels from the misaki-deps image.
# Explicitly excluding CUDA dependencies with torch index-url
RUN /usr/local/bin/uv venv --python 3.10 /app/.venv && \
    /usr/local/bin/uv sync --find-links /wheelhouse --extra cpu \
      --no-index-url "torch.*" \
      --index-url torch,torchaudio,torchvision=https://download.pytorch.org/whl/cpu && \
    # Install Japanese dictionary for fugashi/MeCab
    /app/.venv/bin/pip install unidic fugashi && \
    # Fix MeCab dictionary permissions and ensure the directory exists
    mkdir -p /app/.venv/lib/python3.10/site-packages/unidic/dicdir && \
    chmod -R 755 /app/.venv/lib/python3.10/site-packages/unidic && \
    rm -rf /wheelhouse && \
    chown -R appuser:appuser /app/.venv

# Additional step to verify MeCab and dictionary installation
RUN /app/.venv/bin/python -c "import fugashi; print('MeCab is properly installed')" || echo "Failed to import fugashi"

COPY --chown=appuser:appuser api ./api
COPY --chown=appuser:appuser web ./web
COPY --chown=appuser:appuser docker/scripts/ ./
RUN chmod +x ./entrypoint.sh ./download_model.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/api \
    PATH="/app/.venv/bin:$PATH" \
    UV_LINK_MODE=copy

ENV DOWNLOAD_MODEL=true
# Switch to appuser
USER appuser

# Create a proper download_model.py for the RUN command to use
COPY --chown=appuser:appuser docker/scripts/download_model.sh ./download_model.sh

ENV DEVICE="cpu"
CMD ["./entrypoint.sh"]