#!/usr/bin/env bash
set -e

# EXAMPLE: 
# We assume environment variables are passed in for S3_MODEL_PATH, PROMPT, OUTPUT_S3_PATH, etc.

# Example environment vars (with some defaults):
S3_MODEL_PATH="${S3_MODEL_PATH:-s3://wan-models/Wan2.1-T2V-14B/}"
TASK="${TASK:-t2v-14B}"          # could be t2v-14B or i2v-14B
PROMPT="${PROMPT:-A cat walking in the park}"
OUTPUT_FILE="${OUTPUT_FILE:-output.mp4}"
SIZE="${SIZE:-1280*720}"

echo "=== Downloading model from $S3_MODEL_PATH ==="
# We'll store the model locally in /app/model
mkdir -p /app/model

# NOTE: Requires awscli installed, so either:
apt-get install -y awscli  # OR  pip install awscli
aws s3 cp --recursive "$S3_MODEL_PATH" /app/model

# Once the model is present, we run Wan2.1
# If the user wants text-to-video:
if [ "$TASK" = "t2v-14B" ]; then
  echo "=== Running text-to-video generation ==="
  torchrun --nproc_per_node=8 generate.py \
    --task t2v-14B \
    --size "$SIZE" \
    --ckpt_dir /app/model \
    --dit_fsdp --t5_fsdp --ulysses_size 8 \
    --prompt "$PROMPT" \
    --output_file "$OUTPUT_FILE"
else
  # for i2v, you might pass e.g. IMAGE_PATH as an env var
  echo "=== Running image-to-video generation ==="
  torchrun --nproc_per_node=8 generate.py \
    --task i2v-14B \
    --size "$SIZE" \
    --ckpt_dir /app/model \
    --image examples/some_image.jpg \
    --dit_fsdp --t5_fsdp --ulysses_size 8 \
    --prompt "$PROMPT" \
    --output_file "$OUTPUT_FILE"
fi

# Generate a random UUID at runtime
JOB_ID=$(uuidgen)

# Construct a unique S3 path using that UUID
OUTPUT_S3_PATH="s3://wan-video-outputs/${JOB_ID}/output.mp4"

echo "Using dynamic JOB_ID: $JOB_ID"
echo "Will upload final output to: $OUTPUT_S3_PATH"

aws s3 cp output.mp4 "$OUTPUT_S3_PATH"
echo "Done. File uploaded to $OUTPUT_S3_PATH"

echo "=== Done ==="
