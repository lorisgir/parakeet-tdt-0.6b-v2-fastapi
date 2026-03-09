# Stage 1: Builder stage for installing dependencies
FROM python:3.12-slim AS builder

# Install system dependencies including ffmpeg
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git build-essential ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv for fast package management
RUN pip install --no-cache-dir uv

# Create virtual environment
RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Install NeMo ASR toolkit (installed before project deps for better layer caching)
RUN uv pip install "nemo_toolkit[asr]"

# Copy project definition and source, then install all dependencies
# uv will automatically use the pytorch-cu128 index for torch/torchaudio
COPY ./pyproject.toml .
COPY ./parakeet_service ./parakeet_service
RUN uv pip install ".[dev]"

# Stage 2: Runtime stage
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./parakeet_service ./parakeet_service
COPY .env.example .env
COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

EXPOSE 8000
CMD ["uvicorn", "parakeet_service.main:app", \
     "--host", "0.0.0.0", "--port", "8000"]
