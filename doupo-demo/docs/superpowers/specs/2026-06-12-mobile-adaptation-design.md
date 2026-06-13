# 移动端全面适配设计文档

日期: 2026-06-12
状态: 待审核
范围: Android 导出后的完整触屏体验适配

---

## 1. 背景与现状

项目基于 Godot 4.5 GL Compatibility 渲染器，canvas 分辨率 1280×720，stretch mode = `canvas_items`，stretch aspect = `expand`。所有 UI 使用鼠标事件交互。

> 注：本文档中所有 px 均指 Godot canvas 像素（1280×720 逻辑分辨率下的像素），非 Android 物理像素或 dp。Godot 的 `canvas_items` stretch mode 会自动将 canvas 像素缩放到设备屏幕。

### 现存问题
- 无横屏锁定设置
- 无安全区域处理（刘海、圆角、底部手势条）
- 多个场景按钮 `custom_minimum_size` 为 36px（低于最小触摸目标 48px）
- 字号偏小（15-18px）
- 地图仅有纵向拖拽，无双指缩放
- Android 系统返回手势与左侧边缘 UI 可能冲突

### 有利条件
- Godot 4 默认将 touch 事件转为 mouse 事件（`emulate_mouse_from_touch = true`），大部分按钮点击天然兼容
- 地图已有纵向拖拽滚动逻辑（`map_scene.gd:189-208`）
- 已使用 VBoxLayout + 居中锚点的场景无需大改

---

## 2. 目标

| 目标 | 验收标准 |
|------|---------|
| 可安装可运行 | Android APK 安装后横屏启动，无崩溃 |
| 全场景可操作 | 所有按钮/卡牌/地图节点可触屏操作 |
| 无误触 | 手牌区卡牌间距足够，不会意外打出错误卡牌 |
| 安全区域 | 刘海/圆角/手势条区域不遮挡关键 UI |
| 性能可接受 | 低端设备（骁龙 6 系）战斗无明显卡顿 |

---

## 3. 模块设计

### 3.1 项目级配置（project.godot）

**触屏设置（保持默认即可）：**
```ini
input_devices/pointing/emulate_touch_from_mouse = false  # PC端不模拟触屏
# emulate_mouse_from_touch 默认为 true，无需显式设置
```

文件: `project.godot`，改动量：1 行

---

### 3.2 SafeArea 全局组件

创建 `safe_area.gd` 组件，包裹各场景 UI：

```gdscript
extends Control
## 仅在 Android/iOS 上调整安全区域，PC 上无操作

func _ready():
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        return
    await get_tree().process_frame
    var safe = DisplayServer.get_display_safe_area()
    var win = DisplayServer.window_get_size()
    if win.x <= 0 or win.y <= 0:
        return
    # 将像素安全区域转换为归一化锚点
    anchor_left = safe.position.x / float(win.x)
    anchor_top = safe.position.y / float(win.y)
    anchor_right = safe.end.x / float(win.x)
    anchor_bottom = safe.end.y / float(win.y)
    grow_horizontal = Control.GROW_DIRECTION_BOTH
    grow_vertical = Control.GROW_DIRECTION_BOTH
    offset_left = 0
    offset_top = 0
    offset_right = 0
    offset_bottom = 0
```

用法：各场景将 UI 根容器作为 SafeArea 的子节点。

文件: `scripts/safe_area.gd`（新建），改动量：~30 行
各场景 .tscn 添加 SafeArea 包裹：约 10 个场景

---

### 3.3 战斗场景（combat_scene.gd / combat.tscn）

#### 3.3.1 手牌区

现状：手牌在底部 HBoxContainer 中排列，卡牌宽度 ~100px。
问题：手指粗大，密集排列容易误触。

方案：
- 手牌展开时间距提升到 `separation = 12`（当前默认值偏小）
- 手牌容器底部 padding 增加到 20px（避开 Android 底部手势条）
- 拖拽卡牌时其他卡牌让位逻辑保持不变（已兼容触屏）

#### 3.3.2 结束回合按钮

现状：`custom_minimum_size = Vector2(120, 50)`，字号 18px。
方案：保持不变（已达标），确认锚点定位在右下角安全区域内。

#### 3.3.3 敌人目标选择

现状：拖拽卡牌到敌人上方释放 = 选中目标。
方案：Godot 触屏自动转为 mouse 事件，**无需修改代码**。

#### 3.3.4 状态/遗物/药水栏

现状：顶部横向排列。
方案：图标确认 ≥ 48px，字号 ≥ 16px。

文件: `scripts/combat_scene.gd`、`scenes/combat.tscn`，改动量：~15 行

---

### 3.4 地图场景（map_scene.gd / map.tscn）

#### 3.4.1 现有拖拽（已实现）

地图已有纵向拖拽滚动：`map_scene.gd:189-208` 使用 `InputEventMouseButton` + `InputEventMouseMotion`。Godot 触屏转 mouse 事件后**天然兼容**，无需修改。

#### 3.4.2 画笔触屏适配（关键问题）

**现状：** 画笔使用鼠标右键（`MOUSE_BUTTON_RIGHT`）绘制（`drawing_layer.gd:27`）。触屏无右键，画笔完全不可用。

**方案：** PC 端保留右键画笔不变。触屏端新增 `InputEventScreenTouch` / `InputEventScreenDrag` 处理（这些事件类型不受 `emulate_mouse_from_touch` 影响，与鼠标事件完全独立）。

改动：
- `drawing_layer.gd`：原有 `MOUSE_BUTTON_RIGHT` 逻辑保持不变（PC 不受影响）
- `drawing_layer.gd`：新增 `InputEventScreenTouch` + `InputEventScreenDrag` 分支（工具激活时触摸 = 绘制）
- `drawing_layer.gd`：添加信号 `is_drawing_changed`
- `map_scene.gd`：收到 `is_drawing_changed(true)` 时暂停拖拽滚动
- 工具未激活时，画笔层 `_input` 开头直接 return，触摸事件自动转为 mouse 左键传递给 map_scene 处理滚动

#### 3.4.3 双指缩放（新增）

与现有单指拖拽的冲突处理：
- 单指 = 拖拽平移（现有逻辑）
- 双指 = 缩放（新增）
- 切换逻辑：检测到 `InputEventScreenTouch`（index 1，pressed=true）时设置 `_is_pinching = true`，暂停单指拖拽
- 手指抬起边界：当 index 1 的 `InputEventScreenTouch`（pressed=false）到达时，如果 index 0 仍在触摸则回到单指拖拽模式；若两指均抬起则重置
- 在现有 `_input` 的单指拖拽分支中增加守卫：`if is_dragging and not _is_pinching`
- 使用 `InputEventScreenTouch` / `InputEventScreenDrag` 检测多点触控（这些事件不受 `emulate_mouse_from_touch` 影响）
- 缩放范围：`scale = 0.6 ~ 1.5`

#### 3.4.4 画图工具栏

已修复底部锚点定位（本次会话已做）。
按钮 `custom_minimum_size` 从 36px 提升到 48px。

文件: `scripts/map_scene.gd`、`scenes/map.tscn`，改动量：~60 行

---

### 3.5 Android 返回手势冲突

Android 13+ 默认从屏幕左边缘右滑 = 系统返回。这与地图画笔/卡牌拖拽左侧起点冲突。

方案：
- 在左侧 UI 元素的 `_input` 中增加守卫：忽略起始 X 位置 < 20px（canvas 像素）的触摸事件
- 战斗场景手牌区在底部，不受影响
- 此方案不依赖任何实验性 API，确定可用

文件: `scripts/map_scene.gd`，改动量：~5 行

---

### 3.6 角色选择 / 卡牌详情面板

现状：角色选择使用 VBoxLayout 居中，天然兼容触屏。卡牌详情面板为弹窗覆盖层，点击外部关闭。
方案：**无需修改**，确认按钮尺寸 ≥ 48px 即可。

---

### 3.7 商店/休息/奖励/事件场景

现状：已使用 VBoxLayout 居中布局。
方案：
- 确认所有 Button 的 `custom_minimum_size.y ≥ 48`
- 事件选项按钮高度 ≥ 48px

文件: `scenes/shop.tscn`、`scenes/event.tscn` 等，改动量：~10 行

---

## 4. 不改动的部分

| 组件 | 原因 |
|------|------|
| 战斗逻辑（battle_manager.gd） | 纯逻辑层，不涉及输入 |
| 存档系统 | 无 UI 依赖 |
| 敌人 AI / 意图系统 | 无 UI 依赖 |
| 卡牌数据（CardData） | 纯数据 |
| 遗物/药水效果逻辑 | 纯逻辑 |
| 角色选择场景（character_select.tscn） | VBoxLayout 居中，天然兼容触屏 |
| 卡牌详情面板（card_detail_panel.gd） | 弹窗覆盖层，点击外部关闭 |

---

## 5. 实施顺序

| 阶段 | 内容 | 预估文件数 | 依赖 |
|------|------|-----------|------|
| P0 | project.godot 触屏配置 + 返回手势防护 | 1 | 无 |
| P1 | SafeArea 组件 + 各场景接入 | 12 | P0 |
| P2 | 战斗场景手牌区间距 + 底部 padding | 3 | P1 |
| P3 | 地图双指缩放（含与现有拖拽的冲突处理） | 2 | P1 |
| P4 | 全场景按钮/字号检查 + 放大到 48px | 6 | P1 |

总计约 20 个文件，~180 行新增/修改代码。

---

## 6. 风险与缓解

| 风险 | 缓解 |
|------|------|
| SafeArea API 在低版本 Android 不可用 | 平台守卫：非 Android/iOS 直接跳过 |
| 双指缩放与现有纵向拖拽冲突 | 二指检测时暂停单指拖拽；手指抬起时正确处理状态回退 |
| Android 返回手势干扰左侧操作 | 左侧 20px 边距守卫，不依赖实验性 API |
| 手牌拖拽在触屏下延迟 | Godot 触屏事件默认无延迟 |
| 低端设备性能 | GL Compatibility 已是最轻量渲染器 |
