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
RELEASE_VERSION = "v0.1.1"

CARD_FILES = [
    PROJECT / "data" / "cards_xiaoyan.json",
    PROJECT / "data" / "cards_xuner.json",
    PROJECT / "data" / "cards_cailin.json",
]

RELEASE_ARTIFACTS = [
    PROJECT / "windows" / "斗破苍穹·斗帝之路 - Demo.exe",
    PROJECT / "Android" / "斗破苍穹·斗帝之路 - Demo.apk",
    ROOT / "downloads" / f"doupo-demo-{RELEASE_VERSION}.exe",
    ROOT / "downloads" / f"doupo-demo-{RELEASE_VERSION}.apk",
    ROOT / "downloads" / f"doupo-demo-{RELEASE_VERSION}-macos.zip",
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
    "relics": 59,
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


def _parse_scene_node_paths(scene_text: str) -> tuple[dict[str, str], set[str]]:
    ext_resources: dict[str, str] = {}
    node_paths: set[str] = set()

    ext_pattern = re.compile(r'\[ext_resource[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"[^\]]*\]')
    for path, resource_id in ext_pattern.findall(scene_text):
        ext_resources[resource_id] = path

    node_pattern = re.compile(r'\[node\s+name="([^"]+)"(?:[^\]]*parent="([^"]+)")?[^\]]*\]')
    for name, parent in node_pattern.findall(scene_text):
        if not parent or parent == ".":
            node_paths.add(name)
        else:
            node_paths.add(f"{parent}/{name}")

    return ext_resources, node_paths


def _parse_root_script(scene_text: str, ext_resources: dict[str, str]) -> str:
    root_match = re.search(r'\[node\s+name="[^"]+"[^\]]*\](?P<body>.*?)(?=\n\[node|\Z)', scene_text, re.DOTALL)
    if not root_match:
        return ""
    script_match = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', root_match.group("body"))
    if not script_match:
        return ""
    return ext_resources.get(script_match.group(1), "")


def check_scene_root_node_paths(errors: list[str]) -> None:
    """Validate literal $Node paths used by root scene scripts."""
    ignored_prefixes = {
        "%",  # unique-name paths are resolved by Godot ownership, not simple scene path text.
    }

    for scene_path in sorted((PROJECT / "scenes").glob("*.tscn")):
        scene_text = scene_path.read_text(encoding="utf-8", errors="ignore")
        ext_resources, node_paths = _parse_scene_node_paths(scene_text)
        root_script_ref = _parse_root_script(scene_text, ext_resources)
        if not root_script_ref.startswith("res://"):
            continue
        script_path = res_to_path(root_script_ref)
        if not script_path.exists():
            errors.append(f"{scene_path.relative_to(ROOT)}: root script missing {root_script_ref}")
            continue

        script_text = script_path.read_text(encoding="utf-8", errors="ignore")
        literal_paths = set(re.findall(r'\$([A-Za-z_][A-Za-z0-9_]*(?:/[A-Za-z_][A-Za-z0-9_]*)*)', script_text))
        for literal_path in sorted(literal_paths):
            if any(literal_path.startswith(prefix) for prefix in ignored_prefixes):
                continue
            if literal_path not in node_paths:
                errors.append(
                    f"{script_path.relative_to(ROOT)}: literal node path ${literal_path} "
                    f"not found in {scene_path.relative_to(ROOT)}"
                )


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
        f"https://github.com/bro622/doupo-demo/releases/download/{RELEASE_VERSION}/doupo-demo-{RELEASE_VERSION}.exe",
        f"https://github.com/bro622/doupo-demo/releases/download/{RELEASE_VERSION}/doupo-demo-{RELEASE_VERSION}.apk",
        f"https://github.com/bro622/doupo-demo/releases/download/{RELEASE_VERSION}/doupo-demo-{RELEASE_VERSION}-macos.zip",
    ]
    for link in expected_links:
        if link not in text:
            errors.append(f"{download_page.relative_to(ROOT)}: missing download link {link}")
    for label in [f"{RELEASE_VERSION} · 916MB", f"{RELEASE_VERSION} · 849MB", f"{RELEASE_VERSION} · 885MB"]:
        if label not in text:
            errors.append(f"{download_page.relative_to(ROOT)}: missing expected release size label {label}")


def check_website_index_counts(errors: list[str]) -> None:
    index_page = ROOT / "website" / "index.html"
    text = index_page.read_text(encoding="utf-8")
    expected_tokens = [
        "174张卡牌",
        '<div class="stat-num">174</div>',
        "59 件遗物",
        "47 个剧情事件",
    ]
    for token in expected_tokens:
        if token not in text:
            errors.append(f"{index_page.relative_to(ROOT)}: missing current release count token {token!r}")


def check_website_search_page(errors: list[str]) -> None:
    search_page = ROOT / "website" / "search.html"
    if not search_page.exists():
        errors.append(f"missing website search page: {search_page.relative_to(ROOT)}")
        return

    text = search_page.read_text(encoding="utf-8")
    required_tokens = [
        'script src="cards-data.js"',
        'script src="relics-data.js"',
        'script src="events-data.js"',
        'script src="enemies-data.js"',
        "function buildSearchIndex",
        "new URLSearchParams(window.location.search)",
        "cards.html?card=",
        "relics.html?relic=",
        "event-detail.html?id=",
        "enemy-detail.html?id=",
        "typeFilters",
    ]
    for token in required_tokens:
        if token not in text:
            errors.append(f"{search_page.relative_to(ROOT)}: missing search implementation token {token!r}")

    nav_pages = [
        ROOT / "website" / "index.html",
        ROOT / "website" / "cards.html",
        ROOT / "website" / "relics.html",
        ROOT / "website" / "events.html",
        ROOT / "website" / "event-detail.html",
        ROOT / "website" / "enemies.html",
        ROOT / "website" / "enemy-detail.html",
        ROOT / "website" / "download.html",
    ]
    for page in nav_pages:
        if 'href="search.html"' not in page.read_text(encoding="utf-8"):
            errors.append(f"{page.relative_to(ROOT)}: missing search navigation link")

    for page, token in {
        ROOT / "website" / "cards.html": "function openCardFromUrl",
        ROOT / "website" / "relics.html": "function openRelicFromUrl",
    }.items():
        if token not in page.read_text(encoding="utf-8"):
            errors.append(f"{page.relative_to(ROOT)}: missing search result deep-link handler {token}")


def check_website_event_preview_rules(errors: list[str]) -> None:
    events_page = ROOT / "website" / "events.html"
    text = events_page.read_text(encoding="utf-8")
    required_tokens = [
        "function getEventChoiceCount",
        "function formatPreviewText",
        "replace(/\\\\n|\\n/g, ' ')",
        "const previewDescription = formatPreviewText(event.description)",
        "event.character_choices",
        "Object.values(event.character_choices)",
        "const choiceCount = getEventChoiceCount(event)",
        "${choiceCount} 个选项",
    ]
    for token in required_tokens:
        if token not in text:
            errors.append(f"{events_page.relative_to(ROOT)}: missing ancient-event preview choice count token {token!r}")
    if "${event.choices ? event.choices.length : 0} 个选项" in text:
        errors.append(f"{events_page.relative_to(ROOT)}: event preview still counts only event.choices")
    if "${event.description || ''}" in text:
        errors.append(f"{events_page.relative_to(ROOT)}: event preview still renders raw description text")


def check_website_ui_consistency(errors: list[str]) -> None:
    event_detail = ROOT / "website" / "event-detail.html"
    for page in [
        ROOT / "website" / "events.html",
        event_detail,
    ]:
        text = page.read_text(encoding="utf-8")
        required_tokens = [
            "ZCOOL+XiaoWei",
            "--display:",
            "font-family: var(--display)",
            ".nav-brand::before",
            '<a href="index.html" class="nav-brand">斗破苍穹</a>',
            '<a href="enemies.html">敌人</a>',
            '<a href="search.html">搜索</a>',
        ]
        for token in required_tokens:
            if token not in text:
                errors.append(f"{page.relative_to(ROOT)}: missing shared website UI token {token!r}")
        if "斗破苍穹·斗帝之路</a>" in text:
            errors.append(f"{page.relative_to(ROOT)}: event navigation brand still uses long title")

    event_detail_text = event_detail.read_text(encoding="utf-8")
    for token in [
        "function getVisibleOutcomes",
        "event.id !== 0",
        "o.type === 'HEAL' && o.desc === '恢复全部生命值'",
        "getVisibleOutcomes(event, c)",
    ]:
        if token not in event_detail_text:
            errors.append(f"{event_detail.relative_to(ROOT)}: missing Bodhi tree outcome display filter token {token!r}")
    if "const choiceOutcomes = c.outcomes || [];" in event_detail_text:
        errors.append(f"{event_detail.relative_to(ROOT)}: event detail still renders raw choice outcomes")

    for page in [
        ROOT / "website" / "cards.html",
        ROOT / "website" / "relics.html",
        ROOT / "website" / "enemies.html",
    ]:
        text = page.read_text(encoding="utf-8")
        if "padding: 112px 24px 32px" not in text:
            errors.append(f"{page.relative_to(ROOT)}: codex page header must leave room for fixed nav")
        if "padding: 96px 16px 24px" not in text:
            errors.append(f"{page.relative_to(ROOT)}: mobile codex page header must leave room for fixed nav")


def check_release_copy_alignment(errors: list[str]) -> None:
    expected_tokens = {
        ROOT / "game-design" / "05-系统策划.md": [
            "当前实现共计 **47 个事件**",
            "| **合计** | | **59** | |",
            "**当前实现合计** | **47**",
            "全部 47 个事件",
            "由场景四【古界之门】选项 A 设置 `ancient_clan_heritage` 标记",
            "进入休息点时，自动回复 15 点生命值",
        ],
        ROOT / "game-design" / "07-事件系统.md": [
            "当前实现共计 47 个事件",
            "场景三 · 迦南学院 (10个主场景事件 + 1个古族传承链式事件)",
            "由场景四【古界之门】选项 A 写入 `ancient_clan_heritage` 标记",
            "抽到的第一张诅咒牌将被自动消耗并重新抽一张牌",
            "进入休息节点自动回复 15 HP",
            "有【燃烧】或【蛇毒】的敌人受伤 +30%",
            "回合结束能量为 0 时，下回合多抽 1 牌",
            "战斗开始获得 15 护盾",
            "遗物 `药族秘传`",
            "回合结束给予所有敌人 2 层【燃烧】",
        ],
        ROOT / "game-design" / "09-诅咒牌汇总.md": [
            "抽到的第一张诅咒牌将被自动消耗并重新抽一张牌",
        ],
        ROOT / "website" / "download.html": [
            "59件遗物",
            "47个剧情事件",
        ],
        ROOT / "website" / "relics.html": [
            "59件遗物",
        ],
        ROOT / "website" / "relics-data.js": [
            '"id": 59',
            '"name": "七彩灵鹤羽"',
        ],
    }

    forbidden_tokens = {
        ROOT / "game-design" / "05-系统策划.md": [
            "全游戏共计 **43 个事件**",
            "全部 43 个事件",
            "| **合计** | | **58** | |",
            "灵药圃**（事件遗物）：进入休息点时额外回复 5 点生命值",
        ],
        ROOT / "game-design" / "07-事件系统.md": [
            "全游戏共计 43 个事件",
            "随机将手牌中 1 张诅咒牌移除",
            "每次休息时额外回复 5 点 HP",
            "随机施加 1 层【易伤】或【虚弱】",
            "手牌中每保留或剩余一张卡牌",
            "第三回合结束时再次获得 10 点护盾",
            "药族秘传令",
            "每回合开始时自动清除自身所有负面状态",
        ],
        ROOT / "game-design" / "09-诅咒牌汇总.md": [
            "随机将手牌中 1 张诅咒牌移除",
        ],
        ROOT / "website" / "download.html": [
            "58件遗物",
        ],
        ROOT / "website" / "relics.html": [
            "58件遗物",
        ],
    }

    for path, tokens in expected_tokens.items():
        text = path.read_text(encoding="utf-8")
        for token in tokens:
            if token not in text:
                errors.append(f"{path.relative_to(ROOT)}: missing aligned copy token {token!r}")

    for path, tokens in forbidden_tokens.items():
        text = path.read_text(encoding="utf-8")
        for token in tokens:
            if token in text:
                errors.append(f"{path.relative_to(ROOT)}: stale copy token remains {token!r}")


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


def check_event_relic_name_alignment(errors: list[str]) -> None:
    relic_text = (PROJECT / "scripts" / "relic_database.gd").read_text(encoding="utf-8")
    relic_names = {
        relic_id: relic_name
        for relic_id, relic_name in re.findall(r'RelicData\.new\((\d+),\s*"([^"]+)"', relic_text)
    }
    outcome_pattern = re.compile(
        r'add_outcome\(OutcomeType\.RELIC\s*,\s*0\s*,\s*"(\d+)"\s*,\s*"([^"]*)"'
    )

    for path in sorted((PROJECT / "scripts" / "events").rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for relic_id, desc in outcome_pattern.findall(text):
            relic_name = relic_names.get(relic_id)
            if relic_name and relic_name not in desc:
                errors.append(
                    f"{path.relative_to(ROOT)}: relic outcome desc {desc!r} does not match "
                    f"ref {relic_id} ({relic_name})"
                )

    events_data_path = ROOT / "website" / "events-data.js"
    events_data_text = events_data_path.read_text(encoding="utf-8")
    exported_pattern = re.compile(
        r'"type":\s*"RELIC",\s*"value":\s*0,\s*"ref":\s*"(\d+)",\s*"desc":\s*"([^"]*)"',
        re.DOTALL,
    )
    for relic_id, desc in exported_pattern.findall(events_data_text):
        relic_name = relic_names.get(relic_id)
        if relic_name and relic_name not in desc:
            errors.append(
                f"{events_data_path.relative_to(ROOT)}: relic outcome desc {desc!r} does not match "
                f"ref {relic_id} ({relic_name})"
            )


def _extract_js_array_assignment(text: str, const_name: str) -> list:
    start = text.find(f"const {const_name} =")
    if start == -1:
        raise ValueError(f"missing const {const_name}")
    array_start = text.find("[", start)
    if array_start == -1:
        raise ValueError(f"missing array for const {const_name}")

    depth = 0
    for idx in range(array_start, len(text)):
        char = text[idx]
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                return json.loads(text[array_start:idx + 1])
    raise ValueError(f"unterminated array for const {const_name}")


def check_website_event_export_alignment(errors: list[str]) -> None:
    events_data_path = ROOT / "website" / "events-data.js"
    try:
        exported_events = _extract_js_array_assignment(events_data_path.read_text(encoding="utf-8"), "EVENTS")
    except Exception as exc:
        errors.append(f"{events_data_path.relative_to(ROOT)}: cannot parse EVENTS export: {exc}")
        return

    exported_by_file = {event.get("file", ""): event for event in exported_events}
    outcome_pattern = re.compile(
        r'\.add_outcome\(OutcomeType\.([A-Z0-9_]+)\s*,\s*(-?\d+)\s*,\s*"([^"]*)"\s*,\s*"([^"]*)"\)'
    )

    for path in sorted((PROJECT / "scripts" / "events").rglob("*.gd")):
        if path.name in EVENT_SUPPORT_FILES:
            continue
        text = path.read_text(encoding="utf-8")
        class_match = re.search(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.MULTILINE)
        if class_match and class_match.group(1) in EVENT_SUPPORT_CLASSES:
            continue

        script_outcomes = [
            (kind, int(value), ref, desc)
            for kind, value, ref, desc in outcome_pattern.findall(text)
        ]
        exported = exported_by_file.get(path.name)
        if exported is None:
            errors.append(f"{events_data_path.relative_to(ROOT)}: missing exported event {path.name}")
            continue

        exported_outcomes = [
            (outcome.get("type", ""), int(outcome.get("value", 0)), outcome.get("ref", ""), outcome.get("desc", ""))
            for choice in exported.get("choices", [])
            for outcome in choice.get("outcomes", [])
        ]
        if script_outcomes != exported_outcomes:
            errors.append(f"{events_data_path.relative_to(ROOT)}: exported outcomes do not match {path.name}")

        id_match = re.search(r"^\s*id\s*=\s*(-?\d+)", text, re.MULTILINE)
        scene_match = re.search(r"^\s*scene_id\s*=\s*(-?\d+)", text, re.MULTILINE)
        if id_match and int(exported.get("id", -999)) != int(id_match.group(1)):
            errors.append(f"{events_data_path.relative_to(ROOT)}: exported id mismatch for {path.name}")
        if scene_match and int(exported.get("scene_id", -999)) != int(scene_match.group(1)):
            errors.append(f"{events_data_path.relative_to(ROOT)}: exported scene_id mismatch for {path.name}")


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


def _extract_function_body(text: str, func_name: str) -> str:
    start_match = re.search(rf"^func\s+{re.escape(func_name)}\s*\([^)]*\).*?:", text, re.MULTILINE)
    if not start_match:
        return ""
    start = start_match.start()
    next_match = re.search(r"^func\s+[A-Za-z_][A-Za-z0-9_]*\s*\(", text[start_match.end():], re.MULTILINE)
    end = start_match.end() + next_match.start() if next_match else len(text)
    return text[start:end]


def _function_returns_literal_one(text: str, func_name: str) -> bool:
    body = _extract_function_body(text, func_name)
    return bool(re.search(r"^\s*return\s+1\s*$", body, re.MULTILINE))


def check_save_restore_symmetry(errors: list[str]) -> None:
    for rel_path in [
        PROJECT / "scripts" / "player_manager.gd",
        PROJECT / "scripts" / "run_manager.gd",
    ]:
        text = rel_path.read_text(encoding="utf-8")
        save_body = _extract_function_body(text, "get_save_data")
        restore_body = _extract_function_body(text, "restore_data")
        if not save_body or not restore_body:
            errors.append(f"{rel_path.relative_to(ROOT)}: missing get_save_data/restore_data function")
            continue

        saved_keys = set(re.findall(r'"([A-Za-z0-9_]+)"\s*:', save_body))
        restored_keys = set(re.findall(r'data\.get\("([A-Za-z0-9_]+)"', restore_body))
        intentionally_write_only: set[str] = set()
        intentionally_read_only: set[str] = set()

        for key in sorted(saved_keys - restored_keys - intentionally_write_only):
            errors.append(f"{rel_path.relative_to(ROOT)}: save key is not restored: {key}")
        for key in sorted(restored_keys - saved_keys - intentionally_read_only):
            errors.append(f"{rel_path.relative_to(ROOT)}: restore key is not saved: {key}")


def check_room_state_persistence_rules(errors: list[str]) -> None:
    shop_text = (PROJECT / "scripts" / "shop_scene.gd").read_text(encoding="utf-8")
    treasure_text = (PROJECT / "scripts" / "treasure_room.gd").read_text(encoding="utf-8")
    main_text = (PROJECT / "scripts" / "main.gd").read_text(encoding="utf-8")

    shop_save = _extract_function_body(shop_text, "_save_inventory_to_state")
    shop_load = _extract_function_body(shop_text, "_load_inventory_from_save")
    for key in ["cards", "relics", "potions"]:
        if f'inv["{key}"]' not in shop_save:
            errors.append(f"doupo-demo/scripts/shop_scene.gd: shop inventory does not save {key}")
        if f'inv.get("{key}"' not in shop_load:
            errors.append(f"doupo-demo/scripts/shop_scene.gd: shop inventory does not load {key}")
    for token in [
        '"id": item.relic.id',
        '"price": item.price',
        '"sold": item.sold',
        'CardData.from_dict(d)',
        'PotionDatabase.get_potion',
    ]:
        if token not in shop_text:
            errors.append(f"doupo-demo/scripts/shop_scene.gd: missing shop persistence token {token!r}")

    if "RunManager.treasure_chest_opened = true" not in treasure_text:
        errors.append("doupo-demo/scripts/treasure_room.gd: opening chest must mark treasure_chest_opened")
    enter_treasure = _extract_function_body(main_text, "_enter_treasure_room")
    complete_treasure = _extract_function_body(main_text, "_on_treasure_completed")
    for token in [
        "PlayerManager.gold = max(0, PlayerManager.gold - RunManager.pending_treasure_gold)",
        "PlayerManager.remove_relic(relic_id)",
        "RunManager.treasure_chest_opened = false",
        "SaveManager.capture_checkpoint()",
        "SaveManager.save_game()",
    ]:
        if token not in enter_treasure:
            errors.append(f"doupo-demo/scripts/main.gd: treasure room restore path missing {token!r}")
    for token in [
        "RunManager.pending_treasure_relic_ids.clear()",
        "RunManager.pending_treasure_gold = 0",
        "RunManager.treasure_chest_opened = false",
        "RunManager.saved_phase = -1",
    ]:
        if token not in complete_treasure:
            errors.append(f"doupo-demo/scripts/main.gd: treasure completion path missing {token!r}")


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


def check_card_effect_execution_coverage(cards: list[dict], errors: list[str]) -> None:
    meta_keys = {
        "id",
        "name",
        "type",
        "rarity",
        "cost",
        "description",
        "detail",
        "character_id",
        "image_path",
        "tags",
    }
    known_indirect_keys = {
        # Keyword marker; the executable value is devour_max_hp_bonus.
        "devour",
        # STATUS behavior is represented by CardType.STATUS and battle cleanup.
        "is_status_card",
        # Recalculated into Player.ability_burn_no_decay for the active ability.
        "burn_no_decay",
    }

    active_keys = {
        key
        for card in cards
        for key, value in card.items()
        if not key.startswith("upgraded_")
        and key not in meta_keys
        and key not in known_indirect_keys
        and value not in (None, "", 0, False, [], -1)
    }

    handler_text = ""
    excluded_files = {"card_data.gd", "card_loader.gd", "card_database.gd", "player_manager.gd"}
    for path in (PROJECT / "scripts").rglob("*.gd"):
        if path.name in excluded_files:
            continue
        handler_text += path.read_text(encoding="utf-8", errors="ignore") + "\n"

    card_data_text = (PROJECT / "scripts" / "card_data.gd").read_text(encoding="utf-8")
    useful_card_data_lines = [
        line
        for line in card_data_text.splitlines()
        if "var " not in line and "d.get" not in line and not re.search(r'"[A-Za-z0-9_]+":', line)
    ]
    handler_text += "\n".join(useful_card_data_lines)

    for key in sorted(active_keys):
        if not re.search(rf"\b{re.escape(key)}\b", handler_text):
            count = sum(1 for card in cards if card.get(key) not in (None, "", 0, False, [], -1))
            errors.append(f"card effect field has no execution reference: {key} ({count} cards)")


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


def check_internal_gameplay_rules(cards: list[dict], errors: list[str]) -> None:
    by_id = {card.get("id"): card for card in cards}
    battle_manager = PROJECT / "scripts" / "battle_manager.gd"
    player_script = PROJECT / "scripts" / "player.gd"
    relic_db = PROJECT / "scripts" / "relic_database.gd"
    relic_manager = PROJECT / "scripts" / "relic_manager.gd"
    rest_scene = PROJECT / "scripts" / "rest_scene.gd"
    shop_scene = PROJECT / "scripts" / "shop_scene.gd"
    shop_manager = PROJECT / "scripts" / "shop_manager.gd"
    potion_manager = PROJECT / "scripts" / "potion_manager.gd"
    combat_scene = PROJECT / "scripts" / "combat_scene.gd"

    battle_text = battle_manager.read_text(encoding="utf-8")
    player_text = player_script.read_text(encoding="utf-8")
    relic_db_text = relic_db.read_text(encoding="utf-8")
    relic_manager_text = relic_manager.read_text(encoding="utf-8")
    rest_text = rest_scene.read_text(encoding="utf-8")
    shop_text = shop_scene.read_text(encoding="utf-8")
    shop_manager_text = shop_manager.read_text(encoding="utf-8")
    potion_manager_text = potion_manager.read_text(encoding="utf-8")
    combat_text = combat_scene.read_text(encoding="utf-8")

    sync_start = battle_text.find("func _sync_deck_to_manager")
    sync_block = battle_text[sync_start:battle_text.find("## 使用药水", sync_start)]
    if "CardType.STATUS" not in sync_block:
        errors.append(f"{battle_manager.relative_to(ROOT)}: battle deck sync must exclude temporary STATUS cards")

    if '"inner_demon_status"' not in player_text or "CardType.STATUS" not in player_text:
        errors.append(f"{player_script.relative_to(ROOT)}: STATUS draw triggers must include inner_demon_status")
    if "DRAW_CURSE_EXHAUST_REDRAW" not in player_text:
        errors.append(f"{player_script.relative_to(ROOT)}: curse charm draw-redraw effect is not handled by effect type")
    if "card_type != CardData.CardType.STATUS" not in player_text:
        errors.append(f"{player_script.relative_to(ROOT)}: hand text/playability must mark STATUS cards unplayable")

    if "swallow_count" not in battle_text or "回复 %d HP" not in battle_text:
        errors.append(f"{battle_manager.relative_to(ROOT)}: swallow STATUS must heal an enemy at player end turn")

    if 'RelicData.new(53, "诅咒护符"' in relic_db_text:
        relic_53_block = relic_db_text[
            relic_db_text.find('RelicData.new(53, "诅咒护符"'):
            relic_db_text.find('RelicData.new(54, "灵药圃"')
        ]
        if "DRAW_CURSE_EXHAUST_REDRAW" not in relic_53_block:
            errors.append(f"{relic_db.relative_to(ROOT)}: curse charm must use DRAW_CURSE_EXHAUST_REDRAW")

    for relic_id, relic_name in [(42, "大长老手令"), (54, "灵药圃")]:
        token = f'RelicData.new({relic_id}, "{relic_name}"'
        block = relic_db_text[relic_db_text.find(token):relic_db_text.find(f'RelicData.new({relic_id + 1},', relic_db_text.find(token))]
        if "REST_AUTO_HEAL_FLAT" not in block:
            errors.append(f"{relic_db.relative_to(ROOT)}: {relic_name} must use REST_AUTO_HEAL_FLAT")
    if "relic.id == 42" in rest_text or "relic.id == 54" in rest_text:
        errors.append(f"{rest_scene.relative_to(ROOT)}: rest auto-heal must be effect-type driven, not relic-id driven")

    if "randi() % 50 + 1" in relic_manager_text:
        errors.append(f"{relic_manager.relative_to(ROOT)}: random relic rewards must not use fixed 1..50 id range")
    if "_grant_random_available_relic" not in relic_manager_text:
        errors.append(f"{relic_manager.relative_to(ROOT)}: random relic rewards must filter all registered available relics")

    space_crack = by_id.get("space_crack", {})
    if not space_crack.get("retain"):
        errors.append("cards_xiaoyan.json: space_crack must retain in hand until battle ends")
    if '"base_price" in item' in shop_text:
        errors.append(f"{shop_scene.relative_to(ROOT)}: shop save must not use dictionary-style membership checks on item objects")
    for path, text in [
        (shop_manager, shop_manager_text),
        (potion_manager, potion_manager_text),
    ]:
        if "测试用：全部1金" in text \
                or _function_returns_literal_one(text, "_calc_price") \
                or _function_returns_literal_one(text, "_calc_relic_price") \
                or _function_returns_literal_one(text, "_calc_potion_price"):
            errors.append(f"{path.relative_to(ROOT)}: shop prices must use release pricing, not 1-gold test pricing")
    if "enemies[0]" in _extract_function_body(potion_manager_text, "use_potion"):
        errors.append(f"{potion_manager.relative_to(ROOT)}: attack potions must use selected target_index, not the first enemy")
    if "func use_potion(potion_index: int, target_index: int = -1)" not in battle_text:
        errors.append(f"{battle_manager.relative_to(ROOT)}: battle potion use must accept a target_index for throwable potions")
    if "SELECTING_POTION_TARGET" not in combat_text:
        errors.append(f"{combat_scene.relative_to(ROOT)}: combat scene must provide enemy targeting for throwable potions")


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
        "tools/*",
        "tools/**/*",
        "res://tools/*",
        "res://tools/**/*",
    ]
    for pattern in required_patterns:
        if pattern not in text:
            errors.append(f"export_presets.cfg must exclude development addon pattern {pattern}")
    for line in text.splitlines():
        if line.startswith("export_files=") and "godot_mcp" in line:
            errors.append("export_presets.cfg must not explicitly list development addon files in export_files")
    if "dotnet/include_debug_symbols=true" in text:
        errors.append("export_presets.cfg must not include Mono debug symbols in release exports")
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
        if binary_contains(artifact, b"remove_background") or binary_contains(artifact, b"res://tools"):
            errors.append(f"{artifact.relative_to(ROOT)}: release artifact contains development tool scripts")
        if artifact.suffix.lower() == ".apk":
            try:
                with zipfile.ZipFile(artifact) as apk:
                    for name in apk.namelist():
                        if "godot_mcp" in name or "addons/godot_mcp" in name:
                            errors.append(f"{artifact.relative_to(ROOT)}: APK contains development addon entry {name}")
                            break
                    for name in apk.namelist():
                        if name.startswith("assets/tools/") or "remove_background" in name:
                            errors.append(f"{artifact.relative_to(ROOT)}: APK contains development tool entry {name}")
                            break
            except zipfile.BadZipFile as exc:
                errors.append(f"{artifact.relative_to(ROOT)}: invalid APK zip payload: {exc}")


def main() -> int:
    errors: list[str] = []
    cards = load_cards(errors)
    check_release_counts(cards, errors)
    check_required_scenes(errors)
    check_scene_root_node_paths(errors)
    check_static_res_refs(errors)
    check_audio_refs(errors)
    check_enemy_assets(errors)
    check_design_card_alignment(errors)
    check_website_card_export(cards, errors)
    check_website_download_page(errors)
    check_website_index_counts(errors)
    check_website_search_page(errors)
    check_website_event_preview_rules(errors)
    check_website_ui_consistency(errors)
    check_release_copy_alignment(errors)
    check_event_refs(cards, errors)
    check_event_relic_name_alignment(errors)
    check_website_event_export_alignment(errors)
    check_event_registration(errors)
    check_event_outcome_handlers(errors)
    check_event_combat_refs(errors)
    check_event_permanent_strength_flow(errors)
    check_event_flag_flow(errors)
    check_save_restore_symmetry(errors)
    check_room_state_persistence_rules(errors)
    check_card_data_serialization(cards, errors)
    check_card_effect_execution_coverage(cards, errors)
    check_relic_effect_handlers(errors)
    check_internal_gameplay_rules(cards, errors)
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
