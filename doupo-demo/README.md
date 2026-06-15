# 斗破苍穹·斗帝之路 Godot Demo

这是《斗破苍穹·斗帝之路》的 Godot 4.5 工程目录。项目是一款同人卡牌 Roguelike Demo，核心玩法包括多角色牌组构筑、遗物联动、事件抉择、地图推进、商店/休息/宝箱房间以及多阶段 Boss 战。

## 版本信息

- **当前版本**：v0.1.1
- **支持平台**：Windows / Android / macOS
- **内容规模**：3 角色、4 场景、54 敌人、174 卡牌、59 遗物、47 事件

## 运行方式

1. 安装 [Godot 4.5](https://godotengine.org/download)
2. 使用 Godot 打开本目录下的 `project.godot`
3. 按 F5 运行

## 主要目录

```text
assets/      游戏图片、音频、UI 资源
data/        角色卡牌 JSON 数据
scenes/      Godot 场景文件
scripts/     游戏逻辑脚本
shaders/     UI 与视觉效果 shader
themes/      Godot UI 主题
```

## 发行下载

| 平台 | 文件 |
| --- | --- |
| Windows | [doupo-demo-v0.1.1.exe](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.exe) |
| Android | [doupo-demo-v0.1.1.apk](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1.apk) |
| macOS | [doupo-demo-v0.1.1-macos.zip](https://github.com/bro622/doupo-demo/releases/download/v0.1.1/doupo-demo-v0.1.1-macos.zip) |

## 发行检查

发行前从仓库根目录运行：

```powershell
python tools\audit_godot_data.py
```

该审计会检查卡牌字段执行覆盖、遗物效果处理、事件奖励引用、敌人行动字段、资源路径、存档/读档对称性、商店和宝箱持久化、官网数据同步、导出配置以及发行包是否泄漏开发插件。

## 版权说明

本工程为非官方同人 Demo，不代表原作版权方立场，也不包含对原作 IP 的授权声明；任何公开分发或商业用途请先确认相应授权与合规要求。
