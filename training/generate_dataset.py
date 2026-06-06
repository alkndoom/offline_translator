"""Generate a synthetic, multi-task instruction dataset for the offline
translator's tiny LM — using Claude as the teacher (synthetic distillation).

The dataset teaches FOUR tasks (translate / summarize / simplify / explain)
across aviation + travel domains, in the SAME chat format and with the SAME
per-task system prompts the app uses at inference time — so what the model
learns matches exactly what the app asks for.

Output: train.jsonl / val.jsonl, one JSON object per line:
  {"messages": [
     {"role": "system", "content": "..."},
     {"role": "user", "content": "..."},
     {"role": "assistant", "content": "..."}
  ]}

Usage:
  export ANTHROPIC_API_KEY=sk-ant-...
  python generate_dataset.py --per-combo 40 --out data
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

import anthropic
from pydantic import BaseModel

# Default teacher. Opus 4.8 is the most capable model; it produces high-quality,
# diverse training pairs. (Do NOT pass temperature/top_p — removed on Opus 4.8.)
TEACHER_MODEL = "claude-opus-4-8"

# Languages used for the translate task (mirrors the app's defaults).
TRANSLATE_SOURCE = "English"
TRANSLATE_TARGET = "Turkish"
# Output languages for the non-translate tasks.
OUTPUT_LANGUAGES = ["English", "Turkish"]

DOMAINS = [
    "airplane cabin and in-flight service",
    "airport check-in, security, and boarding",
    "flight delays, cancellations, and rebooking",
    "in-flight safety and emergency instructions",
    "customs, immigration, and baggage claim",
    "hotel check-in, concierge, and local transport",
]

TASKS = ["translate", "summarize", "simplify", "explain"]


# --- App-matching system prompts (keep in sync with the Flutter gateway) ------


def system_prompt(task: str, source: str, target: str) -> str:
    if task == "translate":
        return (
            f"You are a {source} to {target} translation assistant specialized in airplane, airport boarding, cabin, passenger, and flight-related situations."
            f"Your task is to translate the user's sentence between {source} and {target}."
            "Rules:"
            f"- If the input is {source}, translate it into natural {target}."
            f"- If the input is {target}, translate it into natural {source}."
            "- Preserve the meaning, politeness level, urgency, and speaker intent."
            "- Use simple, clear, practical language suitable for airplane passengers and cabin crew."
            "- Do not add explanations."
            "- Do not answer the user's request."
            "- Do not roleplay."
            "- Only return the translated sentence."
            "- For emergency sentences, keep the translation direct and accurate."
            "- For polite requests, preserve politeness naturally."
            "- For announcements or crew instructions, use clear formal language."
        )
    if task == "summarize":
        return (
            f"You are a concise summarization assistant. Summarize the user's text "
            f"in clear {target}. Keep only the key points. Output ONLY the summary "
            f"— no preamble, no notes."
        )
    if task == "simplify":
        return (
            f"You are a plain-language assistant. Rewrite the user's text in simple, "
            f"easy-to-understand {target} while preserving the meaning. Output ONLY "
            f"the simplified text."
        )
    if task == "explain":
        return (
            f"You are an explanation assistant. Explain the meaning of the user's "
            f"word or phrase in clear {target}, briefly, adding a short example if "
            f"helpful. Output ONLY the explanation."
        )
    raise ValueError(f"unknown task: {task}")


# --- Teacher prompt: what kind of (input, ideal-output) pairs to generate -----


def teacher_instruction(task: str, domain: str, source: str, target: str, n: int) -> str:
    common = (
        f"Generate {n} DIVERSE, realistic training examples for a travel assistant, "
        f"in the domain: {domain}. Vary phrasing, length, formality, and speaker "
        f"(passenger, crew, agent). Avoid repetition and near-duplicates.\n\n"
        f"Return each example as an object with 'user' (the input) and 'assistant' "
        f"(the ideal output). Output must be valid for the given schema."
    )
    if task == "translate":
        return (
            f"{common}\n\nTask: TRANSLATION between {source} and {target}.\n"
            f"- For about half the examples, 'user' is a {source} sentence and "
            f"'assistant' is its natural {target} translation.\n"
            f"- For the other half, 'user' is a {target} sentence and 'assistant' is "
            f"its natural {source} translation.\n"
            f"- 'assistant' must contain ONLY the translated sentence, nothing else."
        )
    if task == "summarize":
        return (
            f"{common}\n\nTask: SUMMARIZATION.\n"
            f"- 'user' is a short paragraph (2-5 sentences) of {target} text, e.g. an "
            f"announcement, policy, or itinerary in the domain.\n"
            f"- 'assistant' is a concise {target} summary of only the key points."
        )
    if task == "simplify":
        return (
            f"{common}\n\nTask: SIMPLIFICATION.\n"
            f"- 'user' is a complex or formal {target} sentence/paragraph in the domain.\n"
            f"- 'assistant' rewrites it in simple, easy-to-understand {target}, same meaning."
        )
    if task == "explain":
        return (
            f"{common}\n\nTask: EXPLAIN A TERM.\n"
            f"- 'user' is a travel/aviation term or short phrase (e.g. 'boarding pass', "
            f"'turbulence', 'layover').\n"
            f"- 'assistant' briefly explains it in clear {target}, with a short example "
            f"if helpful."
        )
    raise ValueError(f"unknown task: {task}")


class Example(BaseModel):
    user: str
    assistant: str


class ExampleBatch(BaseModel):
    examples: list[Example]


def generate_batch(
    client: anthropic.Anthropic,
    task: str,
    domain: str,
    source: str,
    target: str,
    n: int,
) -> list[Example]:
    """Ask the teacher for one batch of examples (structured output)."""
    resp = client.messages.parse(
        model=TEACHER_MODEL,
        max_tokens=4096,
        messages=[
            {"role": "user", "content": teacher_instruction(task, domain, source, target, n)}
        ],
        output_format=ExampleBatch,
    )
    out = resp.parsed_output
    return out.examples if out else []


def to_record(task: str, source: str, target: str, ex: Example) -> dict:
    return {
        "messages": [
            {"role": "system", "content": system_prompt(task, source, target)},
            {"role": "user", "content": ex.user},
            {"role": "assistant", "content": ex.assistant},
        ]
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-combo", type=int, default=40,
                        help="examples per (task, domain) combination")
    parser.add_argument("--batch", type=int, default=15,
                        help="examples requested per teacher call")
    parser.add_argument("--out", type=str, default="data", help="output directory")
    parser.add_argument("--val-frac", type=float, default=0.1)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY
    records: list[dict] = []

    for task in TASKS:
        targets = [TRANSLATE_TARGET] if task == "translate" else OUTPUT_LANGUAGES
        for domain in DOMAINS:
            for target in targets:
                source = TRANSLATE_SOURCE if task == "translate" else target
                remaining = args.per_combo
                while remaining > 0:
                    n = min(args.batch, remaining)
                    try:
                        batch = generate_batch(client, task, domain, source, target, n)
                    except Exception as e:  # noqa: BLE001 — keep going on transient errors
                        print(f"  ! {task}/{domain}: {e}")
                        break
                    for ex in batch:
                        if ex.user.strip() and ex.assistant.strip():
                            records.append(to_record(task, source, target, ex))
                    remaining -= n
                print(f"  {task} | {target} | {domain}: total so far {len(records)}")

    rng.shuffle(records)
    n_val = int(len(records) * args.val_frac)
    val, train = records[:n_val], records[n_val:]

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    _write_jsonl(out_dir / "train.jsonl", train)
    _write_jsonl(out_dir / "val.jsonl", val)
    print(f"\nDone: {len(train)} train, {len(val)} val → {out_dir}/")


def _write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
