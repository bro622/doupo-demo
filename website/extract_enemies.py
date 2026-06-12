# -*- coding: utf-8 -*-
"""Extract enemy data from enemy_database.gd and copy sprites."""
import re, json, os, shutil
from PIL import Image

gd_path = "doupo-demo/scripts/enemy_database.gd"
sprites_src = "doupo-demo/assets/enemies"
sprites_dst = "website/assets/enemies"
js_out = "website/enemies-data.js"

os.makedirs(sprites_dst, exist_ok=True)

with open(gd_path, "r", encoding="utf-8") as f:
    content = f.read()

# Parse ENEMY_TEXTURES mapping
textures = {}
for m in re.finditer(r'"([^"]+)":\s*"res://assets/enemies/([^"]+)"', content):
    textures[m.group(1)] = m.group(2)

# Determine scene from sprite path
def scene_from_path(sprite_path):
    if not sprite_path:
        return ''
    for s in ['scene1', 'scene2', 'scene3', 'scene4']:
        if s in sprite_path:
            return s
    return ''

# Parse factory functions
enemies = []
for fm in re.finditer(r'(?:static\s+)?func\s+(create_\w+)\(\)\s*->\s*Enemy:(.*?)(?=(?:static\s+)?func\s+|$)', content, re.DOTALL):
    func_name = fm.group(1)
    body = fm.group(2)

    # Try Enemy.new("name", hp) format first
    enemy_new_m = re.search(r'Enemy\.new\(\s*"([^"]*)"\s*,\s*(\d+)\s*\)', body)
    if enemy_new_m:
        name = enemy_new_m.group(1)
        hp = int(enemy_new_m.group(2))
    else:
        # Fallback to enemy.name = "name" format
        name_m = re.search(r'enemy\.name\s*=\s*"([^"]*)"', body)
        if not name_m:
            continue
        name = name_m.group(1)

        hp_m = re.search(r'enemy\.max_hp\s*=\s*(\d+)', body)
        hp = int(hp_m.group(1)) if hp_m else 0

    etype = 'boss' if 'boss' in func_name else ('elite' if 'elite' in func_name else 'normal')

    sprite = textures.get(name, '')
    scene = scene_from_path(sprite)

    # Fallback: determine scene from func name
    if not scene:
        for keyword, s in [('jia_ma','scene1'),('scene1','scene1'),('black_corner','scene2'),
                           ('scene2','scene2'),('canaan','scene3'),('scene3','scene3'),
                           ('central','scene4'),('scene4','scene4'),('soul_hall','scene4'),
                           ('ancient','scene4'),('pill_tower','scene4'),('huntiandi','scene4')]:
            if keyword in func_name:
                scene = s
                break

    enemies.append({
        "id": func_name,
        "name": name,
        "hp": hp,
        "type": etype,
        "scene": scene,
        "sprite": sprite,
    })

# Deduplicate by name
seen = set()
unique = []
for e in enemies:
    if e["name"] not in seen:
        seen.add(e["name"])
        unique.append(e)
enemies = unique

print(f"Parsed {len(enemies)} enemies")

# Copy and compress sprites
copied = 0
missing = 0
for e in enemies:
    if not e["sprite"]:
        missing += 1
        continue
    src = os.path.join(sprites_src, e["sprite"])
    if not os.path.exists(src):
        found = False
        for scene_dir in ["scene1-jia-ma", "scene2-black-corner", "scene3-canaan", "scene4-central-plains"]:
            for sub in ["normal", "elite", "boss"]:
                alt = os.path.join(sprites_src, scene_dir, sub, os.path.basename(e["sprite"]))
                if os.path.exists(alt):
                    src = alt
                    e["sprite"] = f"{scene_dir}/{sub}/{os.path.basename(e['sprite'])}"
                    found = True
                    break
            if found:
                break

    dst_dir = os.path.join(sprites_dst, os.path.dirname(e["sprite"]))
    os.makedirs(dst_dir, exist_ok=True)
    dst = os.path.join(sprites_dst, e["sprite"])

    if os.path.exists(src):
        try:
            img = Image.open(src)
            w, h = img.size
            if w > 300:
                ratio = 300 / w
                img = img.resize((300, int(h * ratio)), Image.LANCZOS)
            img.save(dst, "PNG", optimize=True)
            copied += 1
        except Exception:
            shutil.copy2(src, dst)
            copied += 1
    else:
        missing += 1

print(f"Sprites: {copied} copied, {missing} missing")

with open(js_out, "w", encoding="utf-8") as f:
    f.write("// Auto-generated enemy data\n")
    f.write(f"const ENEMIES = {json.dumps(enemies, ensure_ascii=False, indent=None)};\n")
print(f"JS: {js_out} ({os.path.getsize(js_out)//1024}KB)")
