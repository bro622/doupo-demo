# 斗破苍穹·斗帝之路

《斗破苍穹·斗帝之路》是一款使用 Godot 4.5 开发的同人卡牌 Roguelike Demo。项目以多角色牌组构筑、事件抉择、遗物联动和阶段 Boss 战为核心，提供 Windows、Android 与 macOS 本地试玩版本，并配套静态官网图鉴。

## 当前版本

- **版本**：v0.1.1
- **平台**：Windows / Android / macOS
- **引擎**：Godot 4.5
- **官网**：https://doupo.vercel.app
- **Release**：https://github.com/bro622/doupo-demo/releases/tag/v0.1.1

## 内容规模

- **3 位可选角色**：萧炎、萧薰儿、彩鳞
- **174 张卡牌**：攻击、技能、能力、诅咒、状态牌
- **59 件遗物**：普通、稀有、史诗、传说品质
- **4 大场景**：加玛帝国、黑角域、迦南学院、中州
- **47 个事件**：普通事件、角色专属事件、守灵事件、链式剧情事件
- **54 个敌人**：普通敌人、精英、场景 Boss、隐藏 Boss

## 核心体验

- 三套角色机制：异火、金印、蛇毒/姿态切换
- 数据驱动的卡牌、遗物、事件和敌人配置
- 地图、商店、休息、宝箱、奖励、存档/读档流程
- 多阶段 Boss 行动与事件触发战斗
- 官网图鉴：卡牌、遗物、事件、敌人、详情页与全站搜索

## 下载

| 平台 | 文件 |
| --- | --- |
| Windows | [doupo-demo-v0.1.1.exe](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.exe) |
| Android | [doupo-demo-v0.1.1.apk](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.apk) |
| macOS | [doupo-demo-v0.1.1-macos.zip](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1-macos.zip) |

## 质量门禁

本仓库包含发行前静态审计脚本：

```powershell
python tools\audit_godot_data.py
```

审计覆盖卡牌序列化、遗物效果处理、事件奖励引用、敌人行动字段、存档/读档对称性、商店/宝箱持久化、官网图鉴数据、导出配置和发行包开发插件泄漏检查。

当前 v0.1.1 本地门禁状态：

- `audit_passed`
- `cards_checked 174`
- Windows / Android / macOS 发行包 SHA256 已记录在 `.wolf/final-release-manifest-2026-06-15.md`

## 项目结构

```text
doupo-demo/
├── assets/           # 游戏素材
├── data/             # 卡牌 JSON 数据
├── scenes/           # Godot 场景
├── scripts/          # 游戏逻辑
│   ├── events/       # 事件系统
│   └── saves/        # 存档系统
├── shaders/          # 着色器
└── project.godot     # Godot 项目配置

website/              # 静态官网与图鉴页面
tools/                # 审计、导出和开发辅助脚本
game-design/          # 当前实现口径的设计文档
```

## 本地运行

1. 安装 [Godot 4.5](https://godotengine.org/download)
2. 克隆仓库
3. 使用 Godot 打开 `doupo-demo/project.godot`
4. 按 F5 运行项目

官网本地预览：

```powershell
cd website
python -m http.server 8766 --bind 127.0.0.1
```

## 版权说明

本项目为基于《斗破苍穹》的非官方同人 Demo。项目不代表原作版权方立场，也不包含对原作 IP 的授权声明；任何公开分发或商业用途请先确认相应授权与合规要求。
