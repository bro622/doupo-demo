# 斗破苍穹 · 音效资源说明

> 来源：Slay the Spire 2 (v4.5) debug_audio 目录
> 提取日期：2026-06-09

---

## 目录结构

```
doupo-audio/
├── sfx/          # 战斗、卡牌、药水、遗物、场景、备用音效 (32个)
└── ui/           # 界面交互音效 (7个)
```

---

## 战斗音效 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `battle_start_1.mp3` | 战斗开始 A | 进入战斗场景，随机选一个 |
| `battle_start_2.mp3` | 战斗开始 B | 同上 |
| `heavy_attack.mp3` | 重击命中 | 高伤害攻击牌打出 |
| `slash_attack.mp3` | 斩击命中 | 普通攻击牌打出 |
| `blunt_attack.mp3` | 钝击/格挡 | 防御牌或反击触发 |
| `dagger_throw.mp3` | 远程/暗器 | 远程攻击牌（如飞刀类） |
| `doom_apply.mp3` | 诅咒/负面状态 | 施加诅咒牌或debuff |
| `death_stinger.mp3` | 死亡音效 | 敌人死亡或玩家死亡 |
| `victory.mp3` | 胜利 | 战斗胜利结算画面 |
| `player_turn.mp3` | 玩家回合 | 玩家回合开始 |
| `enemy_turn.mp3` | 敌人回合 | 敌人回合开始 |
| `hey.mp3` | 受击语音 | 敌人受到攻击 |
| `hiss.mp3` | 蛇类/魔兽音效 | 蛇类敌人登场或攻击 |

## 卡牌音效 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `card_deal.mp3` | 抽牌 | 每回合抽牌动画 |
| `card_exhaust.mp3` | 消耗牌 | 卡牌被消耗（焚诀机制） |
| `card_smith.mp3` | 卡牌升级 | 卡牌锻造/升级时 |
| `burn_card.mp3` | 异火焚牌 | 异火特殊效果触发 |

## 药水音效 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `potion_slosh_1.mp3` | 药水晃动 A | 打开药水栏，随机选 |
| `potion_slosh_2.mp3` | 药水晃动 B | 同上 |
| `potion_slosh_3.mp3` | 药水晃动 C | 同上 |
| `gain_potion.mp3` | 获得药水 | 奖励/商店获得药水 |

## 遗物 & 解锁 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `relic_get.mp3` | 获得遗物 | 奖励/事件获得遗物 |
| `character_unlock.mp3` | 角色解锁 | 新角色解锁完成 |
| `character_unlock_charge.mp3` | 角色解锁蓄力 | 解锁动画前置蓄力音 |

## 场景音效 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `rest_jingle.mp3` | 休息点 A | 进入休息点场景 |
| `rest_jingle_b.mp3` | 休息点 B | 休息点变体 |
| `rest_jingle_c.mp3` | 休息点 C | 休息点变体 |
| `sleep_blanket.mp3` | 休息/恢复 | 休息动画播放中 |
| `doll_room_amb.mp3` | 宝箱房环境音 | 进入宝箱房间 |
| `shovel.mp3` | 挖掘/隐藏 | 触发隐藏内容或挖掘 |

## 备用音效 `sfx/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `regent_intro.wav` | BOSS登场/觉醒 | 可用于BOSS登场或萧炎觉醒动画 |
| `logo_echo.mp3` | 开场/主菜单 | 可用于主菜单背景音或开场Logo |

## UI 音效 `ui/`

| 文件名 | 用途 | 触发时机 |
|--------|------|---------|
| `ui_click.wav` | 按钮点击 | 通用按钮点击反馈 |
| `card_select.mp3` | 选中卡牌 | 手牌悬停/选中 |
| `deny.mp3` | 操作被拒 | 费用不足、目标无效等 |
| `map_hover.mp3` | 地图悬停 | 鼠标悬停地图节点 |
| `map_open.mp3` | 打开地图 | 进入地图界面 |
| `map_ping.mp3` | 新节点出现 | 地图上新节点可交互 |
| `map_split_tick.mp3` | 路径分叉 | 地图路径分叉提示 |

---

## Godot 集成建议

```gdscript
# AudioManager.gd — AutoLoad 单例
# 用 AudioStreamPlayer 节点播放一次性音效

func play_sfx(sfx_name: String) -> void:
    var path := "res://assets/audio/sfx/%s" % sfx_name
    # 用 AudioStreamPlayer 播放

func play_ui(ui_name: String) -> void:
    var path := "res://assets/audio/ui/%s" % ui_name
    # 用 AudioStreamPlayer 播放
```

音频文件导入 Godot 后需设置 Audio Bus：
- `SFX` bus — 战斗/卡牌/药水/遗物音效
- `UI` bus — 界面交互音效
- `Music` bus — 背景音乐（暂无，后续添加）

---

## 注意事项

- `ui_click` 是 `.wav` 格式，`regent_intro` 也是 `.wav`，其余均为 `.mp3`
- 部分音效来自 STS2 原版，商用时需确认授权
- 音效体积较小，适合直接打包进 Godot pck
