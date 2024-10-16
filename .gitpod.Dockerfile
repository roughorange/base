# Stage 1: Install dependencies
FROM python:3.9-slim AS builder

# Install required libraries for building
RUN apt-get update && apt-get install -y git build-essential && rm -rf /var/lib/apt/lists/*

# Set up workspace
WORKDIR /workspace

# Install Python packages in this stage
RUN pip install --upgrade pip
RUN pip install torch
RUN pip install nemo_toolkit[all]
RUN pip install fastapi uvicorn

# Stage 2: Create final image with minimal size
FROM python:3.9-slim

# Copy installed dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=builder /usr/local/bin /usr/local/bin

# Set up the final workspace
WORKDIR /workspace

# Command to run FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
