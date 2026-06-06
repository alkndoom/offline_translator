"""QLoRA fine-tune a small instruct model on the multi-task dataset.

Runs on a single consumer GPU (or Colab). 4-bit base + LoRA adapters keep the
memory footprint low. Trains on the chat-format JSONL from generate_dataset.py.

Usage (Linux/CUDA or Colab):
  pip install -r requirements.txt
  python finetune_qlora.py \
      --base Qwen/Qwen2.5-1.5B-Instruct \
      --data data --out out/adapter

Output: a LoRA adapter in --out. Merge + export to GGUF with export_gguf.py.
"""

from __future__ import annotations

import argparse

import torch
from datasets import load_dataset
from peft import LoraConfig
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from trl import SFTConfig, SFTTrainer


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--base", default="Qwen/Qwen2.5-1.5B-Instruct",
                   help="HF causal-LM instruct base model")
    p.add_argument("--data", default="data", help="dir with train.jsonl / val.jsonl")
    p.add_argument("--out", default="out/adapter")
    p.add_argument("--epochs", type=float, default=3.0)
    p.add_argument("--batch-size", type=int, default=2)
    p.add_argument("--grad-accum", type=int, default=8)
    p.add_argument("--lr", type=float, default=2e-4)
    args = p.parse_args()

    tokenizer = AutoTokenizer.from_pretrained(args.base, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    # 4-bit NF4 base — the "Q" in QLoRA.
    bnb = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
    )
    model = AutoModelForCausalLM.from_pretrained(
        args.base, quantization_config=bnb, device_map="auto", torch_dtype=torch.bfloat16
    )

    # LoRA adapters on the attention + MLP projections.
    peft_config = LoraConfig(
        r=16,
        lora_alpha=32,
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM",
        target_modules=[
            "q_proj", "k_proj", "v_proj", "o_proj",
            "gate_proj", "up_proj", "down_proj",
        ],
    )

    ds = load_dataset(
        "json",
        data_files={
            "train": f"{args.data}/train.jsonl",
            "validation": f"{args.data}/val.jsonl",
        },
    )

    # Render each chat example to a single string via the model's chat template,
    # so training matches the format the app produces at inference time.
    def render(row: dict) -> dict:
        return {"text": tokenizer.apply_chat_template(row["messages"], tokenize=False)}

    ds = ds.map(render, remove_columns=ds["train"].column_names)

    cfg = SFTConfig(
        output_dir=args.out,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=args.grad_accum,
        learning_rate=args.lr,
        logging_steps=10,
        save_strategy="epoch",
        bf16=True,
        dataset_text_field="text",
    )

    trainer = SFTTrainer(
        model=model,
        args=cfg,
        train_dataset=ds["train"],
        eval_dataset=ds["validation"],
        peft_config=peft_config,
    )
    trainer.train()
    trainer.save_model(args.out)
    tokenizer.save_pretrained(args.out)
    print(f"\nLoRA adapter saved to {args.out}")


if __name__ == "__main__":
    main()
