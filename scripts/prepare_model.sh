#!/usr/bin/env bash
#
# Convert a Hugging Face model folder (containing model.safetensors + config +
# tokenizer) into a quantized GGUF, ready for the app's LlamaCppEngine.
#
# Usage:
#   scripts/prepare_model.sh <HF_MODEL_DIR> [QUANT] [OUT_NAME]
#
#   HF_MODEL_DIR  folder with model.safetensors, config.json, tokenizer.json
#   QUANT         quantization type (default: Q4_K_M)
#   OUT_NAME      output file name (default: model.gguf — matches the app)
#
# Prerequisites (host machine): git, python3, cmake, a C++ compiler.
#   macOS:  brew install cmake
#
set -euo pipefail

MODEL_DIR="${1:?Usage: prepare_model.sh <HF_MODEL_DIR> [QUANT] [OUT_NAME]}"
QUANT="${2:-Q4_K_M}"
OUT_NAME="${3:-model.gguf}"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$(pwd)/.llama.cpp}"

# --- 0. Sanity-check the model folder ------------------------------------------
if [[ ! -f "$MODEL_DIR/config.json" ]]; then
  echo "ERROR: $MODEL_DIR/config.json not found."
  echo "You need the whole HF repo folder, not just model.safetensors."
  exit 1
fi
echo "==> Model architecture(s):"
grep -i '"architectures"' "$MODEL_DIR/config.json" || true

# --- 1. Get + build llama.cpp (once) -------------------------------------------
if [[ ! -d "$LLAMA_CPP_DIR" ]]; then
  echo "==> Cloning llama.cpp into $LLAMA_CPP_DIR"
  git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_CPP_DIR"
fi
echo "==> Installing Python conversion deps"
python3 -m pip install -q -r "$LLAMA_CPP_DIR/requirements.txt"

if [[ ! -x "$LLAMA_CPP_DIR/build/bin/llama-quantize" ]]; then
  echo "==> Building llama-quantize"
  cmake -S "$LLAMA_CPP_DIR" -B "$LLAMA_CPP_DIR/build" >/dev/null
  cmake --build "$LLAMA_CPP_DIR/build" --config Release -j --target llama-quantize >/dev/null
fi

# --- 2. Convert safetensors -> GGUF (f16) --------------------------------------
F16="$(pwd)/model-f16.gguf"
echo "==> Converting to f16 GGUF: $F16"
python3 "$LLAMA_CPP_DIR/convert_hf_to_gguf.py" "$MODEL_DIR" \
  --outfile "$F16" --outtype f16

# --- 3. Quantize ----------------------------------------------------------------
echo "==> Quantizing ($QUANT) -> $OUT_NAME"
"$LLAMA_CPP_DIR/build/bin/llama-quantize" "$F16" "$(pwd)/$OUT_NAME" "$QUANT"

echo ""
echo "==> Done: $(pwd)/$OUT_NAME"
ls -lh "$(pwd)/$OUT_NAME"
echo ""
echo "Next: push it to the device (Android debug build):"
echo "  adb push $OUT_NAME /data/local/tmp/$OUT_NAME"
echo "  adb shell run-as com.example.offline_translator \\"
echo "    cp /data/local/tmp/$OUT_NAME \\"
echo "       /data/user/0/com.example.offline_translator/app_flutter/$OUT_NAME"
