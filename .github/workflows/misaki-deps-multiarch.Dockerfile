# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.10
ARG TARGETPLATFORM

# Select the correct wheelhouse based on the target platform
FROM scratch as wheelhouse-selector
ARG PYTHON_VERSION # Re-declare ARG here
COPY wheelhouse-amd64-py${PYTHON_VERSION} /wheelhouse-amd64
COPY wheelhouse-arm64-py${PYTHON_VERSION} /wheelhouse-arm64

# Final stage: Copy the selected wheelhouse
FROM scratch
ARG TARGETPLATFORM
COPY --from=wheelhouse-selector /wheelhouse-${TARGETPLATFORM#linux/} /wheelhouse
