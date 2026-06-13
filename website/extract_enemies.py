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
    enemy_phases = []

    # Extract actions
    actions = []
    for am in re.finditer(r'var\s+a\d+\s*=\s*Enemy\.EnemyAction\.new\(\s*Enemy\.IntentType\.(\w+),\s*"([^"]*)"', body):
        intent = am.group(1)
        action_name = am.group(2)
        action = {"intent": intent, "name": action_name}
        # Find damage, block, hit_count for this action
        pos = am.end()
        next_action = re.search(r'var\s+a\d+\s*=', body[pos:])
        block_end = pos + next_action.start() if next_action else len(body)
        action_block = body[pos:block_end]
        dmg_m = re.search(r'\.damage\s*=\s*(\d+)', action_block)
        if dmg_m:
            action["damage"] = int(dmg_m.group(1))
        blk_m = re.search(r'\.block\s*=\s*(\d+)', action_block)
        if blk_m:
            action["block"] = int(blk_m.group(1))
        hit_m = re.search(r'\.hit_count\s*=\s*(\d+)', action_block)
        if hit_m:
            action["hit_count"] = int(hit_m.group(1))
        weak_m = re.search(r'\.apply_weak\s*=\s*(\d+)', action_block)
        if weak_m:
            action["apply_weak"] = int(weak_m.group(1))
        vuln_m = re.search(r'\.apply_vulnerable\s*=\s*(\d+)', action_block)
        if vuln_m:
            action["apply_vulnerable"] = int(vuln_m.group(1))
        frz_m = re.search(r'\.apply_frozen\s*=\s*(\d+)', action_block)
        if frz_m:
            action["apply_frozen"] = int(frz_m.group(1))
        burn_m = re.search(r'\.apply_burn\s*=\s*(\d+)', action_block)
        if burn_m:
            action["apply_burn"] = int(burn_m.group(1))
        str_m = re.search(r'\.strength_gain\s*=\s*(\d+)', action_block)
        if str_m:
            action["strength_gain"] = int(str_m.group(1))
        heal_m = re.search(r'\.heal\s*=\s*(\d+)', action_block)
        if heal_m:
            action["heal"] = int(heal_m.group(1))
        frail_m = re.search(r'\.apply_frail\s*=\s*(\d+)', action_block)
        if frail_m:
            action["apply_frail"] = int(frail_m.group(1))
        actions.append(action)

    # If no actions found via set_actions, try set_phases (boss pattern)
    if not actions:
        phases = []
        # Find phase array declarations to determine phase boundaries
        phase_decls = list(re.finditer(r'var\s+(phase\d+):\s*Array', body))
        if phase_decls:
            # Extract action variable names from each phase array
            for pi, pd in enumerate(phase_decls):
                phase_name = pd.group(1)
                # Get the array content: [p1_a1, p1_a2, ...]
                arr_match = re.search(rf'var\s+{phase_name}[^=]*=\s*\[([^\]]*)\]', body)
                if not arr_match:
                    continue
                action_vars = [v.strip() for v in arr_match.group(1).split(',')]
                phase_actions = []
                for var_name in action_vars:
                    if not var_name:
                        continue
                    # Find this variable's definition
                    var_pattern = rf'var\s+{re.escape(var_name)}\s*=\s*Enemy\.EnemyAction\.new\(\s*Enemy\.IntentType\.(\w+),\s*"([^"]*)"'
                    var_match = re.search(var_pattern, body)
                    if not var_match:
                        continue
                    action = {"intent": var_match.group(1), "name": var_match.group(2)}
                    # Get properties between this var definition and next var/phase
                    pos = var_match.end()
                    next_var = re.search(r'var\s+\w+\s*=', body[pos:])
                    block_end = pos + next_var.start() if next_var else len(body)
                    ab = body[pos:block_end]
                    dm = re.search(r'\.damage\s*=\s*(\d+)', ab)
                    if dm: action["damage"] = int(dm.group(1))
                    bm = re.search(r'\.block\s*=\s*(\d+)', ab)
                    if bm: action["block"] = int(bm.group(1))
                    hm = re.search(r'\.hit_count\s*=\s*(\d+)', ab)
                    if hm: action["hit_count"] = int(hm.group(1))
                    wm = re.search(r'\.apply_weak\s*=\s*(\d+)', ab)
                    if wm: action["apply_weak"] = int(wm.group(1))
                    vm = re.search(r'\.apply_vulnerable\s*=\s*(\d+)', ab)
                    if vm: action["apply_vulnerable"] = int(vm.group(1))
                    fm = re.search(r'\.apply_frozen\s*=\s*(\d+)', ab)
                    if fm: action["apply_frozen"] = int(fm.group(1))
                    bm2 = re.search(r'\.apply_burn\s*=\s*(\d+)', ab)
                    if bm2: action["apply_burn"] = int(bm2.group(1))
                    sm = re.search(r'\.strength_gain\s*=\s*(\d+)', ab)
                    if sm: action["strength_gain"] = int(sm.group(1))
                    hlm = re.search(r'\.heal\s*=\s*(\d+)', ab)
                    if hlm: action["heal"] = int(hlm.group(1))
                    flm = re.search(r'\.apply_frail\s*=\s*(\d+)', ab)
                    if flm: action["apply_frail"] = int(flm.group(1))
                    phase_actions.append(action)
                phases.append({"name": f"阶段{pi+1}", "actions": phase_actions})
        else:
            # Fallback: extract all boss actions without phase distinction
            for pm in re.finditer(r'var\s+p\d+_a\d+\s*=\s*Enemy\.EnemyAction\.new\(\s*Enemy\.IntentType\.(\w+),\s*"([^"]*)"', body):
                action = {"intent": pm.group(1), "name": pm.group(2)}
                pos = pm.end()
                next_a = re.search(r'var\s+p?\d*_?a\d+\s*=', body[pos:])
                block_end = pos + next_a.start() if next_a else len(body)
                ab = body[pos:block_end]
                dm = re.search(r'\.damage\s*=\s*(\d+)', ab)
                if dm: action["damage"] = int(dm.group(1))
                bm = re.search(r'\.block\s*=\s*(\d+)', ab)
                if bm: action["block"] = int(bm.group(1))
                hm = re.search(r'\.hit_count\s*=\s*(\d+)', ab)
                if hm: action["hit_count"] = int(hm.group(1))
                wm = re.search(r'\.apply_weak\s*=\s*(\d+)', ab)
                if wm: action["apply_weak"] = int(wm.group(1))
                vm = re.search(r'\.apply_vulnerable\s*=\s*(\d+)', ab)
                if vm: action["apply_vulnerable"] = int(vm.group(1))
                fm = re.search(r'\.apply_frozen\s*=\s*(\d+)', ab)
                if fm: action["apply_frozen"] = int(fm.group(1))
                bm2 = re.search(r'\.apply_burn\s*=\s*(\d+)', ab)
                if bm2: action["apply_burn"] = int(bm2.group(1))
                sm = re.search(r'\.strength_gain\s*=\s*(\d+)', ab)
                if sm: action["strength_gain"] = int(sm.group(1))
                hlm = re.search(r'\.heal\s*=\s*(\d+)', ab)
                if hlm: action["heal"] = int(hlm.group(1))
                if not any(a["name"] == action["name"] and a["intent"] == action["intent"] for a in actions):
                    actions.append(action)

        sprite = textures.get(name, '')

        if phases:
            # Map stage sprites for bosses
            boss_stage_sprites = {
                "云山": ["云山.png", "云山2阶段.png"],
                "韩枫": ["韩枫1阶段.png", "韩枫2阶段.png", "韩枫3阶段.png"],
                "陨落心炎": ["陨落心炎一阶段.png", "陨落心炎二阶段.png", "陨落心炎三阶段.png"],
                "魂天帝": ["魂天帝1阶段.png", "魂天帝2阶段.png", "魂天帝3阶段.png", "魂天帝4阶段.png", "魂天帝5阶段.png"],
                "古帝残魂": ["古帝残魂一阶段.png", "古帝残魂二阶段.png", "古帝残魂三阶段.png"],
            }
            stage_sprites = boss_stage_sprites.get(name, [])
            for pi, phase in enumerate(phases):
                if pi < len(stage_sprites):
                    phase["sprite"] = f"{os.path.dirname(sprite)}/{stage_sprites[pi]}"
                else:
                    phase["sprite"] = sprite
                actions.extend(phase["actions"])
            enemy_phases = phases

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

    enemy_data = {
        "id": func_name,
        "name": name,
        "hp": hp,
        "type": etype,
        "scene": scene,
        "sprite": sprite,
        "actions": actions,
    }
    if enemy_phases:
        enemy_data["phases"] = enemy_phases
    enemies.append(enemy_data)

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
