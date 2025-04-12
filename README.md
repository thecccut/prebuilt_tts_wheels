# Prebuilt TTS Wheels

This repository contains prebuilt wheels for Misaki TTS and its dependencies, separated by language and CPU/GPU support to optimize container size and build time.

## Available Build Options

### Languages
Misaki supports the following languages, each available as a separate build:

- `en` - English
- `ja` - Japanese
- `ko` - Korean
- `zh` - Chinese
- `vi` - Vietnamese
- `all` - All languages combined

### Hardware Support
Each language pack can be built with or without GPU support:

- `cpu` - CPU-only build (smaller, no NVIDIA dependencies)
- `gpu` - With CUDA/GPU support (includes NVIDIA libraries)

## Using Language-Specific and CPU/GPU Builds

Each build is available as both:
1. A GitHub release with wheel files
2. A Docker image with prebuilt wheels

### In a Dockerfile

```dockerfile
# For CPU-only English build (smallest possible image)
COPY --from=ghcr.io/remsky/prebuilt_tts_wheels/misaki-deps:0.9.4-en-cpu-py3.10 /wheelhouse /wheelhouse
RUN pip install --no-index --find-links=/wheelhouse misaki[en]==0.9.4

# For GPU-enabled all-languages build
COPY --from=ghcr.io/remsky/prebuilt_tts_wheels/misaki-deps:0.9.4-all-gpu-py3.10 /wheelhouse /wheelhouse
RUN pip install --no-index --find-links=/wheelhouse misaki[en,ja,ko,zh,vi]==0.9.4
```

## Building Wheels

To build wheels for a specific language and hardware combination:

1. Go to the "Actions" tab in this repository
2. Select the "Build Misaki Dependencies Per Language" workflow
3. Click "Run workflow"
4. Enter the Misaki version you want to build
5. Select the language from the dropdown menu
6. Select either "cpu" or "gpu" for hardware support
7. Click "Run workflow"

## Benefits of Separated Builds

- **Reduced Docker Image Size**: 
  - CPU-only builds exclude large NVIDIA CUDA libraries (over 1.5GB)
  - Single language builds exclude unnecessary language models
- **Faster Builds**: Building for a specific language/hardware combination is much faster
- **Targeted Updates**: You can update just one language pack or hardware variant when needed
- **Efficient Deployment**: Use exactly what you need in production

## Container Registry

All images are available on GitHub Container Registry at:
`ghcr.io/remsky/prebuilt_tts_wheels/misaki-deps`