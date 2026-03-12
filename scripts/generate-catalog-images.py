#!/usr/bin/env python3
"""Generate catalog garment images via Replicate FLUX Schnell."""
from __future__ import annotations

import json
import os
import time
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPLICATE_API_TOKEN = os.environ.get("REPLICATE_API_TOKEN", "")
ASSETS_DIR = Path(__file__).parent.parent / "KISE" / "Assets.xcassets" / "Catalog"
MODEL_VERSION = "black-forest-labs/flux-schnell"

CATEGORIES = {
    "tshirt": {"label": "t-shirt", "fits": ["slim", "regular", "oversized"]},
    "shirt": {"label": "button-down shirt", "fits": ["slim", "regular", "oversized"]},
    "polo": {"label": "polo shirt", "fits": ["slim", "regular", "oversized"]},
    "sweater": {"label": "knit sweater", "fits": ["slim", "regular", "oversized"]},
    "hoodie": {"label": "hoodie", "fits": ["slim", "regular", "oversized"]},
    "jacket": {"label": "jacket", "fits": ["slim", "regular", "oversized"]},
    "coat": {"label": "overcoat", "fits": ["slim", "regular", "oversized"]},
    "jeans": {"label": "jeans", "fits": ["slim", "regular", "relaxed", "straight"]},
    "chinos": {"label": "chino pants", "fits": ["slim", "regular", "relaxed", "straight"]},
    "shorts": {"label": "shorts", "fits": ["slim", "regular", "relaxed"]},
    "shoes": {"label": "leather shoes", "fits": ["regular"]},
}

COLORS = [
    ("white", "white"),
    ("cream", "off-white cream"),
    ("light-gray", "light gray"),
    ("charcoal", "charcoal dark gray"),
    ("black", "black"),
    ("navy", "navy blue"),
    ("light-blue", "light blue"),
    ("olive", "olive green"),
    ("khaki", "khaki tan"),
    ("brown", "brown"),
    ("burgundy", "burgundy"),
    ("terracotta", "terracotta orange-brown"),
    ("sage", "sage green"),
    ("indigo", "indigo blue"),
    ("camel", "camel beige"),
]

ARCHETYPE_IMAGES = {
    "old-money": "Aesthetic moodboard collage, old money style, navy blazer, cream sweater, structured clothing, neutral earth tones, understated luxury, quality fabrics, editorial fashion photography",
    "minimalist": "Aesthetic moodboard collage, minimalist fashion, monochrome outfits, clean lines, black white gray palette, simple silhouettes, intentional dressing, editorial fashion photography",
    "smart-casual": "Aesthetic moodboard collage, smart casual style, Oxford shirt, dark jeans, leather shoes, polished relaxed look, versatile layering, editorial fashion photography",
    "streetwear": "Aesthetic moodboard collage, streetwear style, oversized hoodie, sneakers, relaxed fits, graphic elements, urban fashion, editorial fashion photography",
    "classic": "Aesthetic moodboard collage, classic menswear style, navy blazer, white shirt, gray trousers, timeless proportions, traditional combinations, editorial fashion photography",
    "scandinavian": "Aesthetic moodboard collage, Scandinavian fashion, muted earth tones, oatmeal knit, functional design, textured fabrics, cozy minimal style, editorial fashion photography",
}

FIT_DESCRIPTIONS = {
    "slim": "slim fitted tapered",
    "regular": "regular fit",
    "relaxed": "relaxed loose fit",
    "straight": "straight leg cut",
    "oversized": "oversized dropped shoulder",
}


def build_prompt(category_label: str, color_label: str, fit: str) -> str:
    fit_desc = FIT_DESCRIPTIONS[fit]
    return (
        f"A {color_label} {fit_desc} {category_label}, flat lay product photography "
        f"on clean off-white linen background, soft studio lighting from above, "
        f"neatly folded or laid flat, no model, no mannequin, single garment centered, "
        f"Zara catalog style, minimal shadows, high-end product shot, 4k quality"
    )


def create_prediction(prompt: str, aspect_ratio: str = "3:4", retries: int = 3) -> str | None:
    """Start a Replicate prediction with retry on rate limit."""
    data = json.dumps({
        "input": {
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "output_format": "jpg",
            "output_quality": 90,
            "num_outputs": 1,
            "go_fast": True,
        }
    }).encode()

    for attempt in range(retries):
        req = urllib.request.Request(
            f"https://api.replicate.com/v1/models/{MODEL_VERSION}/predictions",
            data=data,
            headers={
                "Authorization": f"Bearer {REPLICATE_API_TOKEN}",
                "Content-Type": "application/json",
                "Prefer": "wait",
            },
        )

        try:
            resp = urllib.request.urlopen(req, timeout=120)
            result = json.loads(resp.read().decode())
            status = result.get("status")
            if status == "succeeded" and result.get("output"):
                output = result["output"]
                return output[0] if isinstance(output, list) else output
            elif status in ("starting", "processing"):
                return poll_prediction(result["id"])
            else:
                print(f"  Prediction failed: {result.get('error', 'unknown')}")
                return None
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < retries - 1:
                wait = (attempt + 1) * 5
                time.sleep(wait)
                continue
            print(f"  API error: {e}")
            return None
        except Exception as e:
            print(f"  API error: {e}")
            return None
    return None


def poll_prediction(prediction_id: str, max_wait: int = 120) -> str | None:
    """Poll a prediction until it completes."""
    url = f"https://api.replicate.com/v1/predictions/{prediction_id}"
    headers = {"Authorization": f"Bearer {REPLICATE_API_TOKEN}"}

    for _ in range(max_wait // 2):
        time.sleep(2)
        req = urllib.request.Request(url, headers=headers)
        try:
            resp = urllib.request.urlopen(req, timeout=30)
            result = json.loads(resp.read().decode())
            if result["status"] == "succeeded":
                output = result["output"]
                return output[0] if isinstance(output, list) else output
            elif result["status"] == "failed":
                print(f"  Prediction failed: {result.get('error')}")
                return None
        except Exception as e:
            print(f"  Poll error: {e}")
    return None


def download_image(url: str, dest: Path) -> bool:
    """Download an image from URL to local path."""
    try:
        req = urllib.request.Request(url)
        resp = urllib.request.urlopen(req, timeout=30)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f"  Download error: {e}")
        return False


def create_imageset(asset_key: str, image_path: Path) -> None:
    """Create an Xcode .imageset directory with Contents.json."""
    imageset_dir = ASSETS_DIR / f"{asset_key}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)

    # Move image into imageset
    final_path = imageset_dir / f"{asset_key}.jpg"
    if image_path != final_path:
        image_path.rename(final_path)

    contents = {
        "images": [
            {
                "filename": f"{asset_key}.jpg",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    (imageset_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def generate_one(asset_key: str, prompt: str, aspect: str = "3:4") -> bool:
    """Generate a single image and save to asset catalog."""
    imageset_dir = ASSETS_DIR / f"{asset_key}.imageset"
    if (imageset_dir / f"{asset_key}.jpg").exists():
        return True  # Already generated

    image_url = create_prediction(prompt, aspect)
    if not image_url:
        return False

    tmp_path = ASSETS_DIR / f"{asset_key}.imageset" / f"{asset_key}.jpg"
    tmp_path.parent.mkdir(parents=True, exist_ok=True)

    if not download_image(image_url, tmp_path):
        return False

    create_imageset(asset_key, tmp_path)
    return True


def main():
    if not REPLICATE_API_TOKEN:
        print("Set REPLICATE_API_TOKEN environment variable")
        return

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    # Catalog folder Contents.json
    (ASSETS_DIR / "Contents.json").write_text(
        json.dumps({"info": {"version": 1, "author": "xcode"}}, indent=2)
    )

    # Build task list
    tasks: list[tuple[str, str, str]] = []  # (asset_key, prompt, aspect_ratio)

    # Archetype moodboard images
    for key, prompt in ARCHETYPE_IMAGES.items():
        tasks.append((key, prompt, "3:4"))

    # Catalog garment images
    for cat_key, cat_info in CATEGORIES.items():
        for color_key, color_label in COLORS:
            for fit in cat_info["fits"]:
                asset_key = f"{cat_key}_{color_key}_{fit}"
                prompt = build_prompt(cat_info["label"], color_label, fit)
                tasks.append((asset_key, prompt, "3:4"))

    # Filter already-generated
    pending = []
    for key, prompt, aspect in tasks:
        imageset_dir = ASSETS_DIR / f"{key}.imageset"
        if (imageset_dir / f"{key}.jpg").exists():
            continue
        pending.append((key, prompt, aspect))

    total = len(tasks)
    already_done = total - len(pending)
    print(f"Total: {total} images, {already_done} already exist, {len(pending)} to generate")

    if not pending:
        print("All images already generated!")
        return

    completed = already_done
    failed = []

    # Process with limited concurrency to avoid rate limits
    with ThreadPoolExecutor(max_workers=2) as pool:
        future_to_key = {}
        for key, prompt, aspect in pending:
            future = pool.submit(generate_one, key, prompt, aspect)
            future_to_key[future] = key

        for future in as_completed(future_to_key):
            key = future_to_key[future]
            try:
                success = future.result()
                completed += 1
                status = "OK" if success else "FAIL"
                if not success:
                    failed.append(key)
                print(f"  [{completed}/{total}] {key}: {status}")
            except Exception as e:
                completed += 1
                failed.append(key)
                print(f"  [{completed}/{total}] {key}: ERROR - {e}")

    print(f"\nDone! {total - len(failed)}/{total} succeeded")
    if failed:
        print(f"Failed ({len(failed)}): {', '.join(failed[:20])}")
        # Save failed list for retry
        (ASSETS_DIR.parent.parent / "failed-images.txt").write_text("\n".join(failed))


if __name__ == "__main__":
    main()
