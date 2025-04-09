# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.10
ARG TARGETPLATFORM

FROM scratch AS final-amd64
ARG PYTHON_VERSION
COPY wheelhouse-amd64-py${PYTHON_VERSION} /wheelhouse

FROM scratch AS final-arm64
ARG PYTHON_VERSION
COPY wheelhouse-arm64-py${PYTHON_VERSION} /wheelhouse

# Select the final image based on the target platform
FROM final-${TARGETPLATFORM#linux/} AS final
