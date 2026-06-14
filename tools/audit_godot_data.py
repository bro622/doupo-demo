#!/usr/bin/env python3
"""Static release-readiness checks for the Godot demo data."""

from __future__ import annotations

import json
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "doupo-demo"

CARD_FILES = [
    PROJECT / "data" / "cards_xiaoyan.json",
    PROJECT / "data" / "cards_xuner.json",
    PROJECT / "data" / "cards_cailin.json",
]

RELEASE_ARTIFACTS = [
    PROJECT / "windows" / "斗破苍穹·斗帝之路 - Demo.exe",
    PROJECT / "Android" / "斗破苍穹·斗帝之路 - Demo.apk",
    ROOT / "downloads" / "doupo-demo-v0.1.0.exe",
    ROOT / "downloads" / "doupo-demo-v0.1.0.apk",
]

DESIGN_CARD_DOCS = [
    (ROOT / "game-design" / "01-角色卡牌-萧炎.md", PROJECT / "data" / "cards_xiaoyan.json"),
    (ROOT / "game-design" / "02-角色卡牌-萧薰儿.md", PROJECT / "data" / "cards_xuner.json"),
    (ROOT / "game-design" / "03-角色卡牌-彩鳞.md", PROJECT / "data" / "cards_cailin.json"),
]

REQUIRED_SCENES = [
    "main",
    "map",
    "combat",
    "reward",
    "shop",
    "rest",
    "event",
    "treasure_room",
    "character_select",
    "card",
    "enemy",
    "card_select_overlay",
    "relic_select_overlay",
]

PLAYER_VISIBLE_PLACEHOLDERS = [
    "待实现",
    "暂代",
    "TODO",
    "FIXME",
]

CARD_DATA_ALIASES = {
    "name": "card_name",
    "type": "card_type",
}

EXPECTED_RELEASE_COUNTS = {
    "characters": 3,
    "scenes": 4,
    "enemies": 54,
    "cards": 174,
    "relics": 58,
    "events": 47,
}

EVENT_SUPPORT_CLASSES = {
    "EventDatabase",
    "EventManager",
    "EventModel",
    "FloorZeroEvent",
}

EVENT_SUPPORT_FILES = {
    "event_database.gd",
    "event_manager.gd",
    "event_model.gd",
    "floor_zero_event.gd",
}


def res_to_path(ref: str) -> Path:
    return PROJECT.joinpath(*ref.removeprefix("res://").split("/"))


def load_cards(errors: list[str]) -> list[dict]:
    all_cards: list[dict] = []
    global_ids: dict[str, str] = {}

    for path in CARD_FILES:
        try:
            cards = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"{path}: cannot parse JSON: {exc}")
            continue

        local_ids: set[str] = set()
        for idx, card in enumerate(cards):
            card_id = card.get("id", "")
            label = f"{path.relative_to(ROOT)}[{idx}]"

            if not card_id:
                errors.append(f"{label}: missing id")
            elif card_id in local_ids:
                errors.append(f"{label}: duplicate id in file: {card_id}")
            elif card_id in global_ids:
                errors.append(f"{label}: duplicate global id also in {global_ids[card_id]}: {card_id}")
            else:
                global_ids[card_id] = str(path.relative_to(ROOT))
            local_ids.add(card_id)

            if not card.get("name"):
                errors.append(f"{label}: missing name")
            if card.get("image_path") and not res_to_path(card["image_path"]).exists():
                errors.append(f"{label}: missing image {card['image_path']}")

        all_cards.extend(cards)

    return all_cards


def check_required_scenes(errors: list[str]) -> None:
    for scene in REQUIRED_SCENES:
        path = PROJECT / "scenes" / f"{scene}.tscn"
        if not path.exists():
            errors.append(f"missing required scene: {path.relative_to(ROOT)}")


def extract_dictionary_block(text: str, const_name: str) -> str:
    pattern = re.compile(rf"const\s+{re.escape(const_name)}\s*:\s*Dictionary\s*=\s*\{{(?P<body>.*?)\n\}}", re.DOTALL)
    match = pattern.search(text)
    return match.group("body") if match else ""


def check_release_counts(cards: list[dict], errors: list[str]) -> None:
    project_text = (PROJECT / "project.godot").read_text(encoding="utf-8")
    relic_text = (PROJECT / "scripts" / "relic_database.gd").read_text(encoding="utf-8")
    enemy_text = (PROJECT / "scripts" / "enemy_database.gd").read_text(encoding="utf-8")
    events_dir = PROJECT / "scripts" / "events"

    counts = {
        "characters": len(CARD_FILES),
        "scenes": EXPECTED_RELEASE_COUNTS["scenes"],
        "enemies": len(re.findall(r'Enemy\.new\("[^"]+",\s*\d+', enemy_text)),
        "cards": len(cards),
        "relics": relic_text.count("RelicData.new("),
        "events": len(
            [
                path
                for path in events_dir.rglob("*.gd")
                if path.name not in {"event_database.gd", "event_manager.gd", "event_model.gd"}
            ]
        ),
    }

    for key, expected in EXPECTED_RELEASE_COUNTS.items():
        actual = counts[key]
        if actual != expected:
            errors.append(f"release count mismatch for {key}: expected {expected}, got {actual}")

    expected_description = (
        f'{counts["characters"]}角色/{counts["scenes"]}场景/{counts["enemies"]}敌人/'
        f'{counts["cards"]}卡牌/{counts["relics"]}遗物/{counts["events"]}事件'
    )
    if expected_description not in project_text:
        errors.append(f"project.godot description must contain current release counts: {expected_description}")


def check_enemy_assets(errors: list[str]) -> None:
    enemy_db = PROJECT / "scripts" / "enemy_database.gd"
    text = enemy_db.read_text(encoding="utf-8")
    enemy_names = set(re.findall(r'Enemy\.new\("([^"]+)",\s*\d+', text))
    texture_keys = set(re.findall(r'"([^"]+)"\s*:\s*"res://assets/enemies/', extract_dictionary_block(text, "ENEMY_TEXTURES")))
    background_keys = set(re.findall(r'"([^"]+)"\s*:\s*"[^"]+"', extract_dictionary_block(text, "ENEMY_BACKGROUNDS")))

    for name in sorted(enemy_names - texture_keys):
        errors.append(f"{enemy_db.relative_to(ROOT)}: enemy has no texture mapping: {name}")
    for name in sorted(enemy_names - background_keys):
        errors.append(f"{enemy_db.relative_to(ROOT)}: enemy has no battle background mapping: {name}")


def check_static_res_refs(errors: list[str]) -> None:
    checked_suffixes = {".gd", ".tscn", ".tres", ".cfg", ".json", ".import"}
    ignored_dirs = {"addons", ".godot"}
    pattern = re.compile(r"res://[^\"'\)\]\s,]+")

    for path in PROJECT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in checked_suffixes:
            continue
        if ignored_dirs.intersection(path.relative_to(PROJECT).parts):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in pattern.finditer(text):
            ref = match.group(0)
            if "*" in ref or "%" in ref or "{" in ref or ref.endswith("/%s.png"):
                continue
            if not res_to_path(ref).exists():
                errors.append(f"{path.relative_to(ROOT)}: missing resource {ref}")


def check_audio_refs(errors: list[str]) -> None:
    audio_root = PROJECT / "assets" / "audio"
    sfx_files = {path.name for path in (audio_root / "sfx").glob("*") if path.is_file() and path.suffix != ".import"}
    ui_files = {path.name for path in (audio_root / "ui").glob("*") if path.is_file() and path.suffix != ".import"}
    bgm_files = {path.name for path in (audio_root / "bgm").glob("*") if path.is_file() and path.suffix != ".import"}

    script_text = ""
    for path in (PROJECT / "scripts").rglob("*.gd"):
        script_text += path.read_text(encoding="utf-8", errors="ignore") + "\n"

    for name in sorted(set(re.findall(r'AudioManager\.sfx\("([^"]+)"', script_text))):
        if name not in sfx_files:
            errors.append(f"AudioManager.sfx references missing SFX file: {name}")

    for name in sorted(set(re.findall(r'AudioManager\.ui\("([^"]+)"', script_text))):
        if name not in ui_files:
            errors.append(f"AudioManager.ui references missing UI audio file: {name}")

    for name in sorted(set(re.findall(r'AudioManager\.play_bgm_once\("([^"]+)"', script_text))):
        if name not in bgm_files:
            errors.append(f"AudioManager.play_bgm_once references missing BGM file: {name}")

    for name in sorted(set(re.findall(r'"([^"]+\.(?:mp3|wav|ogg))"', script_text))):
        if "%" in name or "{" in name:
            continue
        if name in sfx_files or name in ui_files or name in bgm_files:
            continue
        errors.append(f"script references missing audio file: {name}")


def normalize_design_card_name(name: str) -> str:
    return re.sub(r"[（(]通用卡[）)]", "", name).strip()


def check_design_card_alignment(errors: list[str]) -> None:
    row_pattern = re.compile(r"^\|\s*\*\*(?:\d+[A-Za-z]?)\*\*\s*\|\s*\*\*(.+?)\*\*\s*\|")

    for doc_path, data_path in DESIGN_CARD_DOCS:
        doc_names: set[str] = set()
        for line in doc_path.read_text(encoding="utf-8").splitlines():
            match = row_pattern.match(line)
            if match:
                doc_names.add(normalize_design_card_name(match.group(1)))

        cards = json.loads(data_path.read_text(encoding="utf-8"))
        data_names = {
            normalize_design_card_name(card.get("name", ""))
            for card in cards
            if card.get("type") not in {"CURSE", "STATUS"}
        }

        for name in sorted(doc_names - data_names):
            errors.append(
                f"{data_path.relative_to(ROOT)}: design card missing from data "
                f"({doc_path.relative_to(ROOT)}): {name}"
            )

        for name in sorted(data_names - doc_names):
            errors.append(
                f"{data_path.relative_to(ROOT)}: non-curse card is not in design doc "
                f"({doc_path.relative_to(ROOT)}): {name}"
            )


def check_website_card_export(cards: list[dict], errors: list[str]) -> None:
    website_cards_path = ROOT / "website" / "cards-data.js"
    assets_root = ROOT / "website" / "assets" / "cards"
    if not website_cards_path.exists():
        errors.append(f"missing website card export: {website_cards_path.relative_to(ROOT)}")
        return

    text = website_cards_path.read_text(encoding="utf-8")
    match = re.search(r"=\s*(\[.*\]);?\s*$", text, re.DOTALL)
    if not match:
        errors.append(f"{website_cards_path.relative_to(ROOT)}: cannot parse exported card data")
        return

    try:
        website_cards = json.loads(match.group(1))
    except Exception as exc:
        errors.append(f"{website_cards_path.relative_to(ROOT)}: invalid JSON payload: {exc}")
        return

    game_ids = {card["id"] for card in cards if card.get("id")}
    website_ids = {card.get("id", "") for card in website_cards}
    if len(website_cards) != len(cards):
        errors.append(f"{website_cards_path.relative_to(ROOT)}: expected {len(cards)} cards, got {len(website_cards)}")
    for card_id in sorted(game_ids - website_ids):
        errors.append(f"{website_cards_path.relative_to(ROOT)}: missing website card id {card_id}")
    for card_id in sorted(website_ids - game_ids):
        errors.append(f"{website_cards_path.relative_to(ROOT)}: extra website card id {card_id}")

    for card in website_cards:
        card_id = card.get("id", "")
        img_dir = card.get("imgDir", "")
        img = card.get("img", "")
        if not img_dir or not img:
            errors.append(f"{website_cards_path.relative_to(ROOT)}: card {card_id} missing img/imgDir")
            continue
        if not (assets_root / img_dir / img).exists():
            errors.append(f"{website_cards_path.relative_to(ROOT)}: card {card_id} missing website image {img_dir}/{img}")


def check_website_download_page(errors: list[str]) -> None:
    download_page = ROOT / "website" / "download.html"
    text = download_page.read_text(encoding="utf-8")
    expected_links = [
        "https://github.com/bro622/doupo-demo/releases/download/v0.1.0/doupo-demo-v0.1.0.exe",
        "https://github.com/bro622/doupo-demo/releases/download/v0.1.0/doupo-demo-v0.1.0.apk",
    ]
    for link in expected_links:
        if link not in text:
            errors.append(f"{download_page.relative_to(ROOT)}: missing download link {link}")
    for label in ["v0.1.0 · 915MB", "v0.1.0 · 849MB"]:
        if label not in text:
            errors.append(f"{download_page.relative_to(ROOT)}: missing expected release size label {label}")


def check_event_refs(cards: list[dict], errors: list[str]) -> None:
    card_ids = {card["id"] for card in cards if card.get("id")}
    card_keywords = {"", "rare", "epic", "legendary"}
    relic_keywords = {"", "random_common", "rare", "epic", "legendary"}

    relic_text = (PROJECT / "scripts" / "relic_database.gd").read_text(encoding="utf-8")
    relic_ids = set(re.findall(r"RelicData\.new\((\d+),", relic_text))

    outcome_pattern = re.compile(
        r"add_outcome\(OutcomeType\.(CARD|CURSE_CARD|RELIC)\s*,\s*[^,]+,\s*\"([^\"]*)\""
    )
    for path in (PROJECT / "scripts" / "events").rglob("*.gd"):
        text = path.read_text(encoding="utf-8")
        for kind, ref in outcome_pattern.findall(text):
            if kind in {"CARD", "CURSE_CARD"} and ref not in card_keywords and ref not in card_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing card ref {ref}")
            if kind == "RELIC" and ref not in relic_keywords and ref not in relic_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing relic ref {ref}")


def check_event_registration(errors: list[str]) -> None:
    events_dir = PROJECT / "scripts" / "events"
    db_path = events_dir / "event_database.gd"
    db_text = db_path.read_text(encoding="utf-8")
    registered_classes = re.findall(
        r"_register\(\s*([A-Za-z_][A-Za-z0-9_]*)\.new\(\)\s*\)",
        db_text,
    )

    class_paths: dict[str, Path] = {}
    event_ids: dict[int, Path] = {}

    for path in sorted(events_dir.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        class_match = re.search(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.MULTILINE)
        if not class_match:
            errors.append(f"{path.relative_to(ROOT)}: missing class_name")
            continue

        class_name = class_match.group(1)
        if class_name in class_paths:
            errors.append(
                f"{path.relative_to(ROOT)}: duplicate class_name {class_name} also in "
                f"{class_paths[class_name].relative_to(ROOT)}"
            )
        class_paths[class_name] = path

        if path.name in EVENT_SUPPORT_FILES or class_name in EVENT_SUPPORT_CLASSES:
            continue

        id_matches = re.findall(r"^\s*id\s*=\s*(-?\d+)", text, re.MULTILINE)
        if len(id_matches) != 1:
            errors.append(f"{path.relative_to(ROOT)}: expected exactly one event id assignment")
        else:
            event_id = int(id_matches[0])
            if event_id in event_ids:
                errors.append(
                    f"{path.relative_to(ROOT)}: duplicate event id {event_id} also in "
                    f"{event_ids[event_id].relative_to(ROOT)}"
                )
            event_ids[event_id] = path

        scene_matches = re.findall(r"^\s*scene_id\s*=\s*(-?\d+)", text, re.MULTILINE)
        if len(scene_matches) != 1:
            errors.append(f"{path.relative_to(ROOT)}: expected exactly one scene_id assignment")
        else:
            scene_id = int(scene_matches[0])
            if scene_id not in {1, 2, 3, 4}:
                errors.append(f"{path.relative_to(ROOT)}: event scene_id must be 1..4, got {scene_id}")

        if "func get_choices" not in text or "EventChoice.new" not in text:
            errors.append(f"{path.relative_to(ROOT)}: event has no visible choices")

        if class_name not in registered_classes:
            errors.append(f"{path.relative_to(ROOT)}: event class is not registered: {class_name}")

    for class_name in sorted(set(registered_classes) - set(class_paths)):
        errors.append(f"{db_path.relative_to(ROOT)}: registered event class has no script: {class_name}")


def check_event_outcome_handlers(errors: list[str]) -> None:
    events_dir = PROJECT / "scripts" / "events"
    model_path = events_dir / "event_model.gd"
    manager_path = events_dir / "event_manager.gd"
    model_text = model_path.read_text(encoding="utf-8")
    manager_text = manager_path.read_text(encoding="utf-8")

    enum_match = re.search(r"enum\s+OutcomeType\s*\{(?P<body>.*?)\}", model_text, re.DOTALL)
    if not enum_match:
        errors.append(f"{model_path.relative_to(ROOT)}: missing OutcomeType enum")
        return

    outcome_types = set(re.findall(r"^\s*([A-Z][A-Z0-9_]*)\s*,?", enum_match.group("body"), re.MULTILINE))
    handled_types = set(re.findall(r"EventModel\.OutcomeType\.([A-Z][A-Z0-9_]*)", manager_text))
    for outcome_type in sorted(outcome_types - handled_types):
        errors.append(f"{manager_path.relative_to(ROOT)}: OutcomeType has no execution handler: {outcome_type}")

    for path in sorted(events_dir.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        used_types = set(re.findall(r"OutcomeType\.([A-Z][A-Z0-9_]*)", text))
        for outcome_type in sorted(used_types - outcome_types):
            errors.append(f"{path.relative_to(ROOT)}: unknown OutcomeType: {outcome_type}")


def check_event_combat_refs(errors: list[str]) -> None:
    events_dir = PROJECT / "scripts" / "events"
    main_path = PROJECT / "scripts" / "main.gd"
    main_text = main_path.read_text(encoding="utf-8")
    start = main_text.find("func _get_enemies_for_combat_id")
    end = main_text.find("\nfunc ", start + 1)
    if start == -1 or end == -1:
        errors.append(f"{main_path.relative_to(ROOT)}: cannot locate _get_enemies_for_combat_id")
        return

    combat_block = main_text[start:end]
    handled_ids = set(re.findall(r'^\s*"([^"]+)":', combat_block, re.MULTILINE))
    outcome_pattern = re.compile(r'add_outcome\(OutcomeType\.COMBAT\s*,\s*[^,]+,\s*"([^"]+)"')

    for path in sorted(events_dir.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for combat_id in sorted(set(outcome_pattern.findall(text))):
            if combat_id not in handled_ids:
                errors.append(
                    f"{path.relative_to(ROOT)}: event combat id is not handled by "
                    f"{main_path.relative_to(ROOT)}::_get_enemies_for_combat_id: {combat_id}"
                )


def check_event_permanent_strength_flow(errors: list[str]) -> None:
    events_dir = PROJECT / "scripts" / "events"
    manager_path = events_dir / "event_manager.gd"
    battle_manager_path = PROJECT / "scripts" / "battle_manager.gd"
    event_text = "\n".join(path.read_text(encoding="utf-8") for path in events_dir.rglob("*.gd"))
    if "OutcomeType.PERMA_STRENGTH" not in event_text:
        return

    manager_text = manager_path.read_text(encoding="utf-8")
    battle_manager_text = battle_manager_path.read_text(encoding="utf-8")
    if 'get_node_or_null("Main")' in manager_text or '.has("player")' in manager_text:
        errors.append(
            f"{manager_path.relative_to(ROOT)}: PERMA_STRENGTH must not depend on a live Main.player node"
        )
    if "PERMANENT_STRENGTH_FLAG_PREFIX" not in manager_text or "RunManager.add_event_flag" not in manager_text:
        errors.append(
            f"{manager_path.relative_to(ROOT)}: PERMA_STRENGTH must write a persistent event flag"
        )
    if "PERMANENT_STRENGTH_FLAG_PREFIX" not in battle_manager_text or "player.strength += event_strength_bonus" not in battle_manager_text:
        errors.append(
            f"{battle_manager_path.relative_to(ROOT)}: permanent event strength is not applied at battle start"
        )


def check_event_flag_flow(errors: list[str]) -> None:
    scripts_text = ""
    for path in (PROJECT / "scripts").rglob("*.gd"):
        scripts_text += path.read_text(encoding="utf-8", errors="ignore") + "\n"

    produced_flags = set(re.findall(r'OutcomeType\.FLAG\s*,\s*[^,]+,\s*"([^"]+)"', scripts_text))
    produced_flags.update(re.findall(r'add_event_flag\("([^"]+)"\)', scripts_text))

    consumed_flags = set(re.findall(r'has_event_flag\("([^"]+)"\)', scripts_text))
    consumed_flags.update(re.findall(r'remove_event_flag\("([^"]+)"\)', scripts_text))
    consumed_flags.update(re.findall(r'^\s*required_flag\s*=\s*"([^"]+)"', scripts_text, re.MULTILINE))

    dynamic_prefixes = {
        "event_permanent_strength_",
    }
    for flag in sorted(produced_flags - consumed_flags):
        if any(flag.startswith(prefix) for prefix in dynamic_prefixes):
            continue
        errors.append(f"event flag is produced but never consumed: {flag}")

    for flag in sorted(consumed_flags - produced_flags):
        if any(flag.startswith(prefix) for prefix in dynamic_prefixes):
            continue
        errors.append(f"event flag is consumed but never produced: {flag}")


def check_card_data_serialization(cards: list[dict], errors: list[str]) -> None:
    card_data_path = PROJECT / "scripts" / "card_data.gd"
    text = card_data_path.read_text(encoding="utf-8")

    json_keys = {key for card in cards for key in card}
    from_dict_keys = set(re.findall(r'd\.get\("([^"]+)"', text))
    to_dict_keys = set(re.findall(r'"([^"]+)":\s*[A-Za-z_][A-Za-z0-9_\.]*(?:\(|,|\n)', text))
    apply_upgrade_fields = set(re.findall(r"if\s+(upgraded_[A-Za-z0-9_]+)\s*(?:>=|:)", text))

    for key in sorted(json_keys):
        load_key = CARD_DATA_ALIASES.get(key, key)
        if key not in from_dict_keys and load_key not in from_dict_keys:
            errors.append(f"{card_data_path.relative_to(ROOT)}: JSON card key is not loaded by from_dict: {key}")

        if key.startswith("upgraded_") and key not in {"upgraded_description", "upgraded_detail"}:
            if key not in apply_upgrade_fields:
                errors.append(f"{card_data_path.relative_to(ROOT)}: upgrade key is not applied by apply_upgrade: {key}")
        elif key not in {"name", "type"} and key not in to_dict_keys:
            errors.append(f"{card_data_path.relative_to(ROOT)}: JSON card key is not serialized by to_dict: {key}")


def check_relic_effect_handlers(errors: list[str]) -> None:
    relic_db = PROJECT / "scripts" / "relic_database.gd"
    used_effects = set(re.findall(
        r"RelicData\.EffectType\.([A-Z0-9_]+)",
        relic_db.read_text(encoding="utf-8"),
    ))

    handler_text = ""
    for path in (PROJECT / "scripts").rglob("*.gd"):
        if path.name in {"relic_data.gd", "relic_database.gd"}:
            continue
        handler_text += path.read_text(encoding="utf-8", errors="ignore")

    handled_effects = set(re.findall(r"RelicData\.EffectType\.([A-Z0-9_]+)", handler_text))
    for effect in sorted(used_effects - handled_effects):
        errors.append(f"{relic_db.relative_to(ROOT)}: relic effect has no handler reference outside registry: {effect}")


def check_enemy_action_data(cards: list[dict], errors: list[str]) -> None:
    enemy_db = PROJECT / "scripts" / "enemy_database.gd"
    enemy_script = PROJECT / "scripts" / "enemy.gd"
    db_text = enemy_db.read_text(encoding="utf-8")
    enemy_text = enemy_script.read_text(encoding="utf-8")

    card_ids = {card["id"] for card in cards if card.get("id")}
    for card_id in sorted(set(re.findall(r"\.add_card_id\s*=\s*\"([^\"]+)\"", db_text))):
        if card_id not in card_ids:
            errors.append(f"{enemy_db.relative_to(ROOT)}: enemy action adds missing card id: {card_id}")

    action_block = enemy_text[
        enemy_text.find("class EnemyAction:"):enemy_text.find("## 阶段系统")
    ]
    action_fields = set(re.findall(r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)", action_block))
    assigned_fields = {
        field
        for field in re.findall(r"\b\w+\.(\w+)\s*=", db_text)
        if field in action_fields
    }
    executed_fields = set(re.findall(r"intent\.([A-Za-z_][A-Za-z0-9_]*)", enemy_text))
    for field in sorted(assigned_fields - executed_fields - {"description"}):
        errors.append(f"{enemy_script.relative_to(ROOT)}: enemy action field is assigned but never executed: {field}")


def check_player_visible_placeholders(errors: list[str]) -> None:
    paths = [
        PROJECT / "data",
        PROJECT / "scripts" / "events",
        PROJECT / "scripts" / "relic_database.gd",
        PROJECT / "scripts" / "event_scene.gd",
    ]
    for base in paths:
        files = [base] if base.is_file() else list(base.rglob("*"))
        for path in files:
            if not path.is_file() or path.suffix.lower() not in {".gd", ".json"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for token in PLAYER_VISIBLE_PLACEHOLDERS:
                if token in text:
                    errors.append(f"{path.relative_to(ROOT)}: player-visible placeholder token {token!r}")


def check_export_config(errors: list[str]) -> None:
    export_cfg = PROJECT / "export_presets.cfg"
    text = export_cfg.read_text(encoding="utf-8")
    release_tool = ROOT / "tools" / "export_release.py"
    required_patterns = [
        "addons/godot_mcp/*",
        "addons/godot_mcp/**/*",
        "res://addons/godot_mcp/*",
        "res://addons/godot_mcp/**/*",
    ]
    for pattern in required_patterns:
        if pattern not in text:
            errors.append(f"export_presets.cfg must exclude development addon pattern {pattern}")
    if not release_tool.exists():
        errors.append("tools/export_release.py is required for clean local release exports")
        return
    release_text = release_tool.read_text(encoding="utf-8")
    required_tool_tokens = [
        "DEVELOPMENT_ADDONS",
        "addons",
        "godot_mcp",
        "move_development_addons_out",
        "scan_artifact",
    ]
    for token in required_tool_tokens:
        if token not in release_text:
            errors.append(f"tools/export_release.py must contain release guard token {token!r}")


def binary_contains(path: Path, needle: bytes) -> bool:
    overlap = max(len(needle) - 1, 0)
    previous = b""
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                return False
            data = previous + chunk
            if needle in data:
                return True
            previous = data[-overlap:] if overlap else b""


def check_release_artifacts(errors: list[str]) -> None:
    for artifact in RELEASE_ARTIFACTS:
        if not artifact.exists():
            continue
        if binary_contains(artifact, b"godot_mcp"):
            errors.append(f"{artifact.relative_to(ROOT)}: release artifact contains development addon godot_mcp")
        if artifact.suffix.lower() == ".apk":
            try:
                with zipfile.ZipFile(artifact) as apk:
                    for name in apk.namelist():
                        if "godot_mcp" in name or "addons/godot_mcp" in name:
                            errors.append(f"{artifact.relative_to(ROOT)}: APK contains development addon entry {name}")
                            break
            except zipfile.BadZipFile as exc:
                errors.append(f"{artifact.relative_to(ROOT)}: invalid APK zip payload: {exc}")


def main() -> int:
    errors: list[str] = []
    cards = load_cards(errors)
    check_release_counts(cards, errors)
    check_required_scenes(errors)
    check_static_res_refs(errors)
    check_audio_refs(errors)
    check_enemy_assets(errors)
    check_design_card_alignment(errors)
    check_website_card_export(cards, errors)
    check_website_download_page(errors)
    check_event_refs(cards, errors)
    check_event_registration(errors)
    check_event_outcome_handlers(errors)
    check_event_combat_refs(errors)
    check_event_permanent_strength_flow(errors)
    check_event_flag_flow(errors)
    check_card_data_serialization(cards, errors)
    check_relic_effect_handlers(errors)
    check_enemy_action_data(cards, errors)
    check_player_visible_placeholders(errors)
    check_export_config(errors)
    check_release_artifacts(errors)

    if errors:
        print(f"audit_failures {len(errors)}")
        for error in errors:
            print(error)
        return 1

    print("audit_passed")
    print(f"cards_checked {len(cards)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
