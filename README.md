# 斗破苍穹·斗帝之路

基于《斗破苍穹》的同人卡牌 Roguelike 游戏，使用 Godot 4.5 开发。

## 游戏特色

- **3 位可选角色**：萧炎（异火掌控者）、萧薰儿（金印引爆者）、彩鳞（蛇毒姿态者）
- **170+ 张卡牌**：攻击、技能、能力、诅咒、状态等多种类型
- **58 件遗物**：普通、稀有、史诗、传说四档品质
- **4 大场景**：加玛帝国 → 黑角域 → 迦南学院 → 中州
- **47 个事件**：剧情抉择影响游戏进程
- **50+ 种敌人**：普通、精英、Boss 三种类型

## 下载

### Windows
- [doupo-demo-v0.1.1.exe](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.exe)

### Android
- [doupo-demo-v0.1.1.apk](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.apk)

### macOS
- [doupo-demo-v0.1.1-macos.zip](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1-macos.zip)

## 技术栈

- **引擎**：Godot 4.5
- **语言**：GDScript
- **美术**：AI 生成（Midjourney / Stable Diffusion）
- **官网**：纯 HTML/CSS/JS，部署在 Vercel

## 项目结构

```
doupo-demo/
├── addons/           # Godot 插件
├── assets/           # 游戏素材（图片、音频）
├── data/             # 卡牌数据（JSON）
├── scenes/           # Godot 场景文件
├── scripts/          # 游戏逻辑脚本
│   ├── events/       # 事件系统
│   ├── saves/        # 存档系统
│   └── ...
├── shaders/          # 着色器
└── project.godot     # Godot 项目配置
```

## 官网

https://doupo.vercel.app

## 开发

本项目使用 Godot 4.5 开发。如需本地运行：

1. 安装 [Godot 4.5](https://godotengine.org/download)
2. 克隆本仓库
3. 用 Godot 打开 `doupo-demo/project.godot`
4. 按 F5 运行

## 许可证

本项目为同人作品，基于《斗破苍穹》（作者：天蚕土豆）创作。仅供学习交流，不得用于商业用途。
