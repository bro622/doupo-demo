# -*- coding: utf-8 -*-
"""Extract relic data from relic_database.gd and copy icons."""
import re, json, os, shutil
from PIL import Image

gd_path = "doupo-demo/scripts/relic_database.gd"
relics_src = "doupo-demo/assets/ui/relics"
relics_dst = "website/assets/relics"
js_out = "website/relics-data.js"

os.makedirs(relics_dst, exist_ok=True)

with open(gd_path, "r", encoding="utf-8") as f:
    content = f.read()

# Parse all RelicData.new(...) blocks (both var x = and _register() patterns)
relics = []
for bm in re.finditer(r'RelicData\.new\((.*?)\)', content, re.DOTALL):
    args = bm.group(1)
    id_m = re.match(r'\s*(\d+)', args)
    if not id_m:
        continue
    rid = id_m.group(1)
    strings = re.findall(r'"([^"]*)"', args)
    name = strings[0] if strings else ""
    desc = strings[1] if len(strings) > 1 else ""
    rarity_m = re.search(r'RelicData\.Rarity\.(\w+)', args)
    rarity = rarity_m.group(1) if rarity_m else "COMMON"
    # Check exclusive_to only in immediate subsequent lines (until next RelicData.new or _register)
    end_pos = bm.end()
    # Find the boundary: next RelicData.new, _register, or var declaration
    next_boundary = re.search(r'(?:RelicData\.new|_register\(|var\s+\w+\s*=)', content[end_pos:end_pos + 800])
    boundary = end_pos + next_boundary.start() if next_boundary else end_pos + 200
    after = content[end_pos:boundary]
    ex_m = re.search(r'\.set_exclusive_to\("([^"]*)"\)', after)
    exclusive = ex_m.group(1) if ex_m else ""
    relics.append({"id": int(rid), "name": name, "rarity": rarity, "desc": desc, "exclusive": exclusive})

print(f"Parsed {len(relics)} relics")

# Copy and compress icons
copied = 0
missing = 0
for r in relics:
    src = os.path.join(relics_src, f"{r['name']}.png")
    dst = os.path.join(relics_dst, f"{r['name']}.png")
    if os.path.exists(src):
        try:
            img = Image.open(src)
            w, h = img.size
            if w > 200:
                ratio = 200 / w
                img = img.resize((200, int(h * ratio)), Image.LANCZOS)
            img.save(dst, "PNG", optimize=True)
            copied += 1
        except:
            shutil.copy2(src, dst)
            copied += 1
    else:
        missing += 1

print(f"Icons: {copied} copied, {missing} missing")

with open(js_out, "w", encoding="utf-8") as f:
    f.write("// Auto-generated relic data\n")
    f.write(f"const RELICS = {json.dumps(relics, ensure_ascii=False, indent=None)};\n")
print(f"JS: {js_out} ({os.path.getsize(js_out)//1024}KB)")
