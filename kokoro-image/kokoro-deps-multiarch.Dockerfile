# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11
ARG TARGETPLATFORM

FROM scratch AS final-amd64
ARG PYTHON_VERSION
COPY wheelhouse-amd64-py${PYTHON_VERSION} /wheelhouse
# unidic_data is not architecture-specific, so we'll add it in the final stage

FROM scratch AS final-arm64
ARG PYTHON_VERSION
COPY wheelhouse-arm64-py${PYTHON_VERSION} /wheelhouse
# unidic_data is not architecture-specific, so we'll add it in the final stage

# Select the final image based on the target platform
FROM final-${TARGETPLATFORM#linux/} AS final

# Copy unidic_data (not architecture-specific)
# We'll create a common directory in the GitHub workflow
COPY wheelhouse-common/unidic_data/ /wheelhouse/unidic_data/
