# Model fine-tune pipeline (computer-side)

Train the tiny on-device LM to do **all four app tasks** (Translate / Summarize /
Simplify / Explain) across aviation + travel domains, then export a GGUF the app
downloads. **This runs on a computer/GPU (or Colab) — never on the phone.** The
phone only runs inference.

```
generate_dataset.py   →  finetune_qlora.py  →  export_gguf.py  →  prepare_model.sh  →  upload
 (Claude = teacher)       (QLoRA on a GPU)      (merge adapter)    (HF → GGUF Q4)      (GitHub release)
        │                                                                                   │
        └────────────── synthetic multi-task data ──────────────────────────────► app downloads via MODEL_URL
```

## Prerequisites

- **Dataset gen:** any machine with Python + an `ANTHROPIC_API_KEY`.
- **Fine-tuning:** a CUDA GPU with ~12 GB VRAM, or a Colab T4/A100. (Apple Silicon
  can't use `bitsandbytes` 4-bit — use Colab or a Linux GPU box for this step.)
- `pip install -r requirements.txt`

## 1. Generate the dataset (Claude as teacher)

```bash
export ANTHROPIC_API_KEY=sk-ant-...
python generate_dataset.py --per-combo 40 --out data
```

Produces `data/train.jsonl` + `data/val.jsonl` in chat format. Each example uses
the **same per-task system prompt the app uses at runtime**, so training matches
inference. `--per-combo` controls size (40 × 4 tasks × 6 domains ≈ 1–2k examples).
This is **synthetic distillation**: a strong teacher (Opus 4.8) writes the
examples your small model learns from.

> Cost scales with `--per-combo`. Start small (`--per-combo 10`) to sanity-check,
> then scale up.

## 2. QLoRA fine-tune (GPU / Colab)

```bash
python finetune_qlora.py --base Qwen/Qwen2.5-1.5B-Instruct --data data --out out/adapter
```

4-bit base + LoRA adapters → fits a small GPU. Pick an **instruct, causal** base
that's mobile-sized (≤ 3B): `Qwen/Qwen2.5-1.5B-Instruct` (good multilingual incl.
Turkish) or `meta-llama/Llama-3.2-1B-Instruct`. Output is a small LoRA adapter.

## 3. Merge + export to GGUF

```bash
python export_gguf.py --base Qwen/Qwen2.5-1.5B-Instruct --adapter out/adapter --merged out/merged
../scripts/prepare_model.sh out/merged Q4_K_M model.gguf
```

Step 1 folds the adapter into the base; step 2 (the repo's existing
[prepare_model.sh](../scripts/prepare_model.sh)) converts to GGUF and quantizes to
`Q4_K_M` (~1 GB for a 1.5B model). Verify on desktop before shipping:

```bash
./.llama.cpp/build/bin/llama-cli -m model.gguf -p "Translate to Turkish: Fasten your seatbelt."
```

## 4. Ship it to the app

Upload `model.gguf` to a public host and point the app at it. For model
versioning, also publish a tiny JSON manifest and pass its URL to the app.

```bash
gh release create v2 ./model.gguf --repo <you>/offline-translator-models --title "model v2"
```

Example `model_manifest.json`:

```json
{
  "version": "v2",
  "url": "https://github.com/<you>/offline-translator-models/releases/download/v2/model.gguf"
}
```

Run the app with:

```bash
flutter run \
  --dart-define=MODEL_MANIFEST_URL=https://raw.githubusercontent.com/<you>/offline-translator-models/main/model_manifest.json \
  --dart-define=MODEL_URL=https://github.com/<you>/offline-translator-models/releases/download/v2/model.gguf
```

The app's mode selector (Translate / Summarize / Simplify / Explain) now works
end-to-end, because the model was trained on those exact prompts. **No app code
changes** — retraining is purely a new GGUF. When you publish a new model, update
the manifest `version` and `url`; the app will replace its cached local model on
the next model warm-up.

## Notes

- **Chat template:** training and the app both rely on the base model's chat
  template (Qwen/Llama-3 ship one). Keep the same base family you trained on.
- **Library API drift:** `trl` / `transformers` move fast. If a kwarg in
  `finetune_qlora.py` errors, check the installed version's `SFTConfig` signature
  — the script targets a recent `trl` (≥ 0.11).
- **Evaluation (for your report):** hold out some `val.jsonl` examples and compare
  the base vs fine-tuned model with BLEU/chrF (translation) and manual review
  (other tasks) to quantify the gain from multi-task tuning.
