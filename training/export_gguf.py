"""Merge the LoRA adapter into the base model, then point you at GGUF export.

QLoRA produces a small adapter, not a standalone model. To run on the phone we
must (1) merge the adapter back into the base weights, then (2) convert + quantize
to GGUF. This script does step 1; step 2 reuses scripts/prepare_model.sh.

Usage:
  python export_gguf.py \
      --base Qwen/Qwen2.5-1.5B-Instruct \
      --adapter out/adapter \
      --merged out/merged

  # then convert + quantize the merged HF folder to GGUF:
  ../scripts/prepare_model.sh out/merged Q4_K_M model.gguf
"""

from __future__ import annotations

import argparse

import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--base", default="Qwen/Qwen2.5-1.5B-Instruct")
    p.add_argument("--adapter", default="out/adapter")
    p.add_argument("--merged", default="out/merged")
    args = p.parse_args()

    # Load the base in fp16 (NOT 4-bit) so the merge is lossless, then fold the
    # LoRA deltas into the weights.
    print(f"Loading base {args.base} …")
    base = AutoModelForCausalLM.from_pretrained(
        args.base, torch_dtype=torch.float16, device_map="cpu"
    )
    print(f"Applying adapter {args.adapter} …")
    model = PeftModel.from_pretrained(base, args.adapter)
    model = model.merge_and_unload()

    model.save_pretrained(args.merged, safe_serialization=True)
    # Save the tokenizer + chat template alongside (the GGUF converter needs them).
    AutoTokenizer.from_pretrained(args.adapter).save_pretrained(args.merged)

    print(f"\nMerged model written to {args.merged}/")
    print("Next — convert + quantize to GGUF:")
    print(f"  ../scripts/prepare_model.sh {args.merged} Q4_K_M model.gguf")


if __name__ == "__main__":
    main()
