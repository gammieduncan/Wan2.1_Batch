# Dockerfile: Wan2.1 with GPU support, code included, model downloaded at runtime.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 1. Install basic system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3-pip ffmpeg git wget \
    build-essential cmake ninja-build && \
    rm -rf /var/lib/apt/lists/*

# 2. Create a working directory
WORKDIR /app

# 3. Copy Wan2.1 code into the image
COPY . /app/Wan2.1

WORKDIR /app/Wan2.1

# 4. Upgrade pip & install dependencies
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install packaging  # ✅ Install packaging before requirements.txt

# 5. Install dependencies
RUN pip3 install -r requirements.txt
RUN pip3 install "huggingface_hub[cli]" "xfuser>=0.4.1"

# 6. Copy an entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 7. Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

