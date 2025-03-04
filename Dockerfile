# Dockerfile: Wan2.1 with GPU support, code included, model downloaded at runtime.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 1. Install basic system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3-pip ffmpeg git wget && \
    rm -rf /var/lib/apt/lists/*

# 2. Create a working directory
WORKDIR /app

# 3. Copy Wan2.1 code into the image (assuming your local dir has Wan2.1 code)
# If you've cloned Wan2.1 locally, do something like:
#   git clone https://github.com/Wan-Video/Wan2.1.git .
# Then ensure your Docker build context includes Wan2.1 files
COPY . /app/Wan2.1

WORKDIR /app/Wan2.1

# 4. Install Python dependencies
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN pip3 install "huggingface_hub[cli]" "xfuser>=0.4.1"

# 5. Copy an entrypoint script that handles downloading the model from S3 and running generation
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 6. Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
