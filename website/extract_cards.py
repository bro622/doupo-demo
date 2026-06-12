# -*- coding: utf-8 -*-
import json, os, shutil
from PIL import Image

data_dir = "doupo-demo/data"
cards_src = "doupo-demo/assets/cards"
cards_dst = "website/assets/cards"
js_out = "website/cards-data.js"

for sub in ["xiaoyan", "xuner", "cailin", "curses", "shared"]:
    os.makedirs(os.path.join(cards_dst, sub), exist_ok=True)

def load_cards(path, character):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    cards = []
    for c in data:
        img_path = c.get("image_path", "")
        img_name = os.path.basename(img_path) if img_path else ""
        if not img_name:
            continue
        cid = c.get("character_id", "")
        if cid and cid != character:
            actual_char = cid
        else:
            actual_char = character
        is_shared = c.get("type") == "CURSE" and not cid
        img_sub = "curses" if is_shared else actual_char
        cards.append({
            "id": c.get("id", ""),
            "name": c.get("name", ""),
            "cost": c.get("cost", 0),
            "type": c.get("type", ""),
            "rarity": c.get("rarity", ""),
            "desc": c.get("description", ""),
            "detail": c.get("detail", ""),
            "upgraded_desc": c.get("upgraded_description", ""),
            "upgraded_detail": c.get("upgraded_detail", ""),
            "character": actual_char if not is_shared else "shared",
            "img": img_name,
            "img_dir": img_sub
        })
    return cards

xiaoyan = load_cards(os.path.join(data_dir, "cards_xiaoyan.json"), "xiaoyan")
xuner = load_cards(os.path.join(data_dir, "cards_xuner.json"), "xuner")
cailin = load_cards(os.path.join(data_dir, "cards_cailin.json"), "cailin")

all_cards = []
seen_ids = set()
for c in xuner + cailin + xiaoyan:
    if c["id"] not in seen_ids:
        all_cards.append(c)
        seen_ids.add(c["id"])

print(f"Total cards: {len(all_cards)}")

copied = 0
missing = 0
for c in all_cards:
    src = os.path.join(cards_src, c["img_dir"], c["img"])
    if not os.path.exists(src):
        base, ext = os.path.splitext(c["img"])
        for alt_ext in [".png", ".jpg", ".jpeg"]:
            alt = os.path.join(cards_src, c["img_dir"], base + alt_ext)
            if os.path.exists(alt):
                src = alt
                c["img"] = base + alt_ext
                break
    dst = os.path.join(cards_dst, c["img_dir"], c["img"])
    if os.path.exists(src):
        found = True
    else:
        # Search in curses/ dir as fallback for curse cards
        found = False
        if c["type"] == "CURSE":
            alt = os.path.join(cards_src, "curses", c["img"])
            if os.path.exists(alt):
                src = alt
                c["img_dir"] = "curses"
                dst = os.path.join(cards_dst, "curses", c["img"])
                found = True
    if found:
        try:
            img = Image.open(src)
            w, h = img.size
            if w > 400:
                ratio = 400 / w
                img = img.resize((400, int(h * ratio)), Image.LANCZOS)
            if src.lower().endswith((".jpg", ".jpeg")):
                img = img.convert("RGB")
                img.save(dst, "JPEG", quality=80, optimize=True)
            else:
                img.save(dst, "PNG", optimize=True)
            copied += 1
        except Exception as e:
            shutil.copy2(src, dst)
            copied += 1
    else:
        missing += 1

print(f"Images: {copied} copied, {missing} missing")

js_cards = []
for c in all_cards:
    js_cards.append({
        "id": c["id"], "name": c["name"], "cost": c["cost"],
        "type": c["type"], "rarity": c["rarity"],
        "desc": c["desc"], "detail": c["detail"],
        "upgraded": c["upgraded_desc"],
        "upgradedDetail": c.get("upgraded_detail", ""),
        "character": c["character"],
        "img": c["img"], "imgDir": c["img_dir"]
    })

with open(js_out, "w", encoding="utf-8") as f:
    f.write("// Auto-generated card data\n")
    f.write(f"const CARDS = {json.dumps(js_cards, ensure_ascii=False, indent=None)};\n")

print(f"JS: {js_out} ({os.path.getsize(js_out)//1024}KB)")
