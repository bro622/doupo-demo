## 敌人数据库
## 包含全部场景敌人（4主场景）
class_name EnemyDatabase


## 敌人→战斗背景映射（背景ID → 资源路径）
const BACKGROUND_PATHS: Dictionary = {
	# 场景一：加玛帝国
	"town_street": "res://assets/scenes/town_street.png",
	"beast_mountains": "res://assets/scenes/beast_mountains.png",
	"desert_wasteland": "res://assets/scenes/desert_wasteland.png",
	"lava_cave": "res://assets/scenes/lava_cave.png",
	"cloud_sect": "res://assets/scenes/cloud_sect.png",
	# 场景二：黑角域
	"black_corner_street": "res://assets/scenes/black_corner_street.png",
	"blood_sect_temple": "res://assets/scenes/blood_sect_temple.png",
	"fengcheng_poison_swamp": "res://assets/scenes/fengcheng_poison_swamp.png",
	# 场景三：迦南学院
	"canaan_outer_academy": "res://assets/scenes/canaan_outer_academy.png",
	"canaan_inner_academy": "res://assets/scenes/canaan_inner_academy.png",
	"canaan_inner_forest": "res://assets/scenes/canaan_inner_forest.png",
	"blazing_tower_depths": "res://assets/scenes/blazing_tower_depths.png",
	# 场景四：中州
	"pill_tower_hall": "res://assets/scenes/pill_tower_hall.png",
	"soul_hall": "res://assets/scenes/soul_hall.png",
	"ancient_emperor_cave": "res://assets/scenes/ancient_emperor_cave.png",
}

## 敌人→背景ID映射
const ENEMY_BACKGROUNDS: Dictionary = {
	# 场景一：魔兽山脉与边缘小镇
	"山贼": "town_street",
	"赏金猎人": "town_street",
	"魔兽狼": "beast_mountains",
	"高阶魔兽": "beast_mountains",
	# 场景二：塔戈尔大沙漠
	"沙漠毒蝎": "desert_wasteland",
	"蛇人族战士": "desert_wasteland",
	"海波东": "desert_wasteland",
	# 副场景：地底岩浆
	"双头火灵蛇": "lava_cave",
	# 场景三：云岚宗
	"云岚宗外门弟子": "cloud_sect",
	"云岚宗内门弟子": "cloud_sect",
	"葛叶": "cloud_sect",
	"纳兰嫣然": "cloud_sect",
	"云山": "cloud_sect",
	# 场景二：黑角域
	"黑角域杀手": "black_corner_street",
	"暗杀者组织成员": "black_corner_street",
	"黑角域佣兵": "black_corner_street",
	"血宗弟子": "blood_sect_temple",
	"邪修炼药师": "blood_sect_temple",
	"天蛇府刺客": "fengcheng_poison_swamp",
	"天蛇府精锐刺客": "fengcheng_poison_swamp",
	"范痨": "blood_sect_temple",
	"莫天行": "black_corner_street",
	"金老": "black_corner_street",
	"银老": "black_corner_street",
	"韩枫": "blood_sect_temple",
	# 场景三：迦南学院
	"外院弟子": "canaan_outer_academy",
	"内院精英弟子": "canaan_inner_academy",
	"远古火蜥蜴": "blazing_tower_depths",
	"走火入魔者": "blazing_tower_depths",
	"心炎幻影": "blazing_tower_depths",
	"内院森林高阶魔兽": "canaan_inner_forest",
	"林修崖": "canaan_inner_academy",
	"柳擎": "canaan_inner_academy",
	"地魔老鬼": "blazing_tower_depths",
	"韩月": "canaan_inner_academy",
	"紫妍": "canaan_inner_academy",
	"禁地守卫": "canaan_inner_academy",
	"陨落心炎": "blazing_tower_depths",
	# 场景四：中州
	"魂殿护卫": "soul_hall",
	"暗魂使者": "soul_hall",
	"魂殿长老": "soul_hall",
	"远古傀儡": "ancient_emperor_cave",
	"古族战士": "ancient_emperor_cave",
	"灵魂虚影": "ancient_emperor_cave",
	"丹塔守卫": "pill_tower_hall",
	"药丹": "pill_tower_hall",
	"魂灭生": "soul_hall",
	"血河": "soul_hall",
	"硕武": "soul_hall",
	"魔雨": "soul_hall",
	"骨幽": "soul_hall",
	"魂殿尊老": "soul_hall",
	"魂天帝": "ancient_emperor_cave",
	"古帝残魂": "ancient_emperor_cave",
}

## 根据敌人列表确定战斗背景路径
## 直接匹配第一个敌人的背景
static func get_background_path(enemies: Array[Enemy]) -> String:
	for enemy in enemies:
		var name = enemy.char_name
		print("[背景查找] 敌人: '%s', 在表中: %s" % [name, ENEMY_BACKGROUNDS.has(name)])
		if ENEMY_BACKGROUNDS.has(name):
			var bg_id = ENEMY_BACKGROUNDS[name]
			print("[背景查找] bg_id: '%s'" % bg_id)
			if BACKGROUND_PATHS.has(bg_id):
				var path = BACKGROUND_PATHS[bg_id]
				print("[背景查找] 返回路径: '%s'" % path)
				return path
	print("[背景查找] 未匹配，返回空")
	return ""


## 敌人纹理路径映射（名称 → 资源路径）
const ENEMY_TEXTURES: Dictionary = {
	# 场景一：加玛帝国
	"山贼": "res://assets/enemies/scene1-jia-ma/normal/山贼.png",
	"魔兽狼": "res://assets/enemies/scene1-jia-ma/normal/魔兽狼.png",
	"蛇人族战士": "res://assets/enemies/scene1-jia-ma/normal/蛇人族战士.png",
	"沙漠毒蝎": "res://assets/enemies/scene1-jia-ma/normal/沙漠毒蝎.png",
	"高阶魔兽": "res://assets/enemies/scene1-jia-ma/normal/高阶魔兽.png",
	"赏金猎人": "res://assets/enemies/scene1-jia-ma/normal/赏金猎人.png",
	"双头火灵蛇": "res://assets/enemies/scene1-jia-ma/normal/双头火灵蛇.png",
	"云岚宗外门弟子": "res://assets/enemies/scene3-canaan/normal/云岚宗外门弟子.png",
	"云岚宗内门弟子": "res://assets/enemies/scene3-canaan/normal/云岚宗内门弟子.png",
	"葛叶": "res://assets/enemies/scene1-jia-ma/elite/葛叶.png",
	"纳兰嫣然": "res://assets/enemies/scene1-jia-ma/elite/纳兰嫣然.png",
	"海波东": "res://assets/enemies/scene1-jia-ma/elite/海波东.png",
	"云山": "res://assets/enemies/scene1-jia-ma/boss/云山.png",
	"云山2阶段": "res://assets/enemies/scene1-jia-ma/boss/云山2阶段.png",
	# 场景二：黑角域
	"黑角域杀手": "res://assets/enemies/scene2-black-corner/normal/黑角域杀手.png",
	"暗杀者组织成员": "res://assets/enemies/scene2-black-corner/normal/暗杀者组织成员.png",
	"黑角域佣兵": "res://assets/enemies/scene2-black-corner/normal/黑角域佣兵.png",
	"血宗弟子": "res://assets/enemies/scene2-black-corner/normal/血宗弟子.png",
	"邪修炼药师": "res://assets/enemies/scene2-black-corner/normal/邪修炼药师.png",
	"天蛇府刺客": "res://assets/enemies/scene2-black-corner/normal/天蛇府刺客.png",
	"天蛇府精锐刺客": "res://assets/enemies/scene2-black-corner/normal/天蛇府精锐刺客.png",
	"赏金猎人黑角域": "res://assets/enemies/scene2-black-corner/normal/赏金猎人.png",
	"范痨": "res://assets/enemies/scene2-black-corner/elite/范痨.png",
	"莫天行": "res://assets/enemies/scene2-black-corner/elite/莫天行.png",
	"金老": "res://assets/enemies/scene2-black-corner/elite/金老.png",
	"银老": "res://assets/enemies/scene2-black-corner/elite/银老.png",
	"韩枫": "res://assets/enemies/scene2-black-corner/boss/韩枫1阶段.png",
	"韩枫2阶段": "res://assets/enemies/scene2-black-corner/boss/韩枫2阶段.png",
	"韩枫3阶段": "res://assets/enemies/scene2-black-corner/boss/韩枫3阶段.png",
	# 场景三：迦南学院
	"外院弟子": "res://assets/enemies/scene3-canaan/normal/外院弟子.png",
	"内院精英弟子": "res://assets/enemies/scene3-canaan/normal/内院精英弟子.png",
	"远古火蜥蜴": "res://assets/enemies/scene3-canaan/normal/远古火蜥蜴.png",
	"走火入魔者": "res://assets/enemies/scene3-canaan/normal/走火入魔者.png",
	"心炎幻影": "res://assets/enemies/scene3-canaan/normal/心炎幻影.png",
	"内院森林高阶魔兽": "res://assets/enemies/scene3-canaan/normal/内院森林高阶魔兽.png",
	"林修崖": "res://assets/enemies/scene3-canaan/elite/林修崖.png",
	"柳擎": "res://assets/enemies/scene3-canaan/elite/柳擎.png",
	"禁地守卫": "res://assets/enemies/scene3-canaan/elite/禁地守卫.png",
	"韩月": "res://assets/enemies/scene3-canaan/elite/韩月.png",
	"紫妍": "res://assets/enemies/scene3-canaan/elite/紫妍.png",
	"地魔老鬼": "res://assets/enemies/scene3-canaan/elite/地魔老鬼.png",
	"陨落心炎": "res://assets/enemies/scene3-canaan/boss/陨落心炎一阶段.png",
	"陨落心炎2阶段": "res://assets/enemies/scene3-canaan/boss/陨落心炎二阶段.png",
	"陨落心炎3阶段": "res://assets/enemies/scene3-canaan/boss/陨落心炎三阶段.png",
	# 场景四：中州
	"魂殿护卫": "res://assets/enemies/scene4-central-plains/normal/魂殿护卫.png",
	"暗魂使者": "res://assets/enemies/scene4-central-plains/normal/暗魂使者.png",
	"魂殿长老": "res://assets/enemies/scene4-central-plains/normal/魂殿长老.png",
	"远古傀儡": "res://assets/enemies/scene4-central-plains/normal/远古傀儡.png",
	"古族战士": "res://assets/enemies/scene4-central-plains/normal/古族战士.png",
	"灵魂虚影": "res://assets/enemies/scene4-central-plains/normal/灵魂虚影.png",
	"丹塔守卫": "res://assets/enemies/scene4-central-plains/normal/丹塔守卫.png",
	"药丹": "res://assets/enemies/scene4-central-plains/elite/药丹.png",
	"魂灭生": "res://assets/enemies/scene4-central-plains/elite/魂灭生.png",
	"血河": "res://assets/enemies/scene4-central-plains/elite/血河-魂殿四天尊.png",
	"硕武": "res://assets/enemies/scene4-central-plains/elite/硕武-魂殿三天尊.png",
	"魔雨": "res://assets/enemies/scene4-central-plains/elite/魔雨-魂殿九天尊.png",
	"骨幽": "res://assets/enemies/scene4-central-plains/elite/骨幽-魂殿二天尊.png",
	"魂殿尊老": "res://assets/enemies/scene4-central-plains/elite/魂殿尊老.png",
	"魂天帝": "res://assets/enemies/scene4-central-plains/boss/魂天帝1阶段.png",
	"魂天帝2阶段": "res://assets/enemies/scene4-central-plains/boss/魂天帝2阶段.png",
	"魂天帝3阶段": "res://assets/enemies/scene4-central-plains/boss/魂天帝3阶段.png",
	"魂天帝4阶段": "res://assets/enemies/scene4-central-plains/boss/魂天帝4阶段.png",
	"魂天帝5阶段": "res://assets/enemies/scene4-central-plains/boss/魂天帝5阶段.png",
	"古帝残魂": "res://assets/enemies/scene4-central-plains/boss/古帝残魂一阶段.png",
	"古帝残魂2阶段": "res://assets/enemies/scene4-central-plains/boss/古帝残魂二阶段.png",
	"古帝残魂3阶段": "res://assets/enemies/scene4-central-plains/boss/古帝残魂三阶段.png",
}


## 获取敌人纹理路径，不存在则返回空字符串
static func get_texture_path(enemy_name: String) -> String:
	if ENEMY_TEXTURES.has(enemy_name):
		return ENEMY_TEXTURES[enemy_name]
	return ""


## ============================================================
##  普通敌人（9 个工厂函数，其中 6 个在随机池中）
## ============================================================

## 山贼 HP18：挥砍6 / 挥砍6 / 亡命一击9（HP<50%时触发）
static func create_bandit() -> Enemy:
	var enemy = Enemy.new("山贼", 18)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "挥砍")
	a1.damage = 6
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "挥砍")
	a2.damage = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "亡命一击")
	a3.damage = 9
	enemy.set_actions([a1, a2, a3])
	# HP<50%时用亡命一击替代当前意图（每场触发一次）
	enemy.low_hp_threshold = 0.5
	enemy.low_hp_action = a3
	return enemy


## 魔兽狼 HP20：撕咬7 / 连咬3×2 / 撕咬7
static func create_magic_wolf() -> Enemy:
	var enemy = Enemy.new("魔兽狼", 20)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "撕咬")
	a1.damage = 7
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "连咬")
	a2.damage = 3
	a2.hit_count = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "撕咬")
	a3.damage = 7
	enemy.set_actions([a1, a2, a3])
	return enemy


## 云岚宗外门弟子 HP25：护体8 / 风刃7 / 风刃7 / 风缠(脆弱1)
static func create_yunlan_disciple() -> Enemy:
	var enemy = Enemy.new("云岚宗外门弟子", 25)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "护体")
	a1.block = 8
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风刃")
	a2.damage = 7
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风刃")
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "风缠")
	a4.apply_frail = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 蛇人族战士 HP26：毒牙8+蛇毒2 / 蛇鳞6 / 双蛇4×2+蛇毒1
static func create_snake_warrior() -> Enemy:
	var enemy = Enemy.new("蛇人族战士", 26)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒牙")
	a1.damage = 8
	a1.apply_venom = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "蛇鳞")
	a2.block = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "双蛇")
	a3.damage = 4
	a3.hit_count = 2
	a3.apply_venom = 1
	enemy.set_actions([a1, a2, a3])
	return enemy


## 沙漠毒蝎 HP22：潜伏(5护盾+力量3) / 毒尾10+蛇毒2 / 钳击6
static func create_desert_scorpion() -> Enemy:
	var enemy = Enemy.new("沙漠毒蝎", 22)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "潜伏")
	a1.block = 5
	a1.temp_strength = 3  # 临时力量：仅持续到下次行动后（设计文档：下回合攻击+3）
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒尾")
	a2.damage = 10
	a2.apply_venom = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "钳击")
	a3.damage = 6
	enemy.set_actions([a1, a2, a3])
	return enemy


## 云岚宗内门弟子 HP30：风杀指9 / 虚弱1 / 风壁6+反击4 / 裂空斩14
static func create_yunlan_inner() -> Enemy:
	var enemy = Enemy.new("云岚宗内门弟子", 30)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风杀指")
	a1.damage = 9
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "虚弱术")
	a2.apply_weak = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "风壁")
	a3.block = 6
	a3.damage = 4  # 反击
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "裂空斩")
	a4.damage = 14
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 高阶魔兽 HP40：爪裂10 / 尾扫8+燃烧2 / 狂咬7×2
static func create_high_beast() -> Enemy:
	var enemy = Enemy.new("高阶魔兽", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "爪裂")
	a1.damage = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "尾扫")
	a2.damage = 8
	a2.apply_burn = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "狂咬")
	a3.damage = 7
	a3.hit_count = 2
	enemy.set_actions([a1, a2, a3])
	return enemy


## 赏金猎人 HP36：突刺10 / 飞镖6×2 / 烟雾弹(虚弱+脆弱1)
static func create_bounty_hunter() -> Enemy:
	var enemy = Enemy.new("赏金猎人", 36)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "突刺")
	a1.damage = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "飞镖")
	a2.damage = 6
	a2.hit_count = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "烟雾弹")
	a3.apply_weak = 1
	a3.apply_frail = 1
	enemy.set_actions([a1, a2, a3])
	return enemy


## 双头火灵蛇 HP54：火息12+燃烧3 / 毒牙8+蛇毒2 / 双头4×3+燃烧1 / 火鳞10
static func create_fire_snake() -> Enemy:
	var enemy = Enemy.new("双头火灵蛇", 54)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "火息")
	a1.damage = 12
	a1.apply_burn = 3
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒牙")
	a2.damage = 8
	a2.apply_venom = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双头")
	a3.damage = 4
	a3.hit_count = 3
	a3.apply_burn = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "火鳞")
	a4.block = 10
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 获取随机普通敌人（按楼层过滤）
## floor: 当前楼层（0-14），不同子区域解锁不同敌人
static func create_random_normal_enemy(floor: int = 0) -> Enemy:
	var factories: Array[Callable] = []
	# 子区域1（0-4层）：山贼、魔兽狼
	factories.append(create_bandit)
	factories.append(create_magic_wolf)
	# 子区域2（5-9层）：解锁蛇人族战士、沙漠毒蝎
	if floor >= 5:
		factories.append(create_snake_warrior)
		factories.append(create_desert_scorpion)
	# 子区域3（10-14层）：解锁云岚宗弟子
	if floor >= 10:
		factories.append(create_yunlan_disciple)
		factories.append(create_yunlan_inner)
	var idx = RNGManager.monster_rng.randi() % factories.size()
	return factories[idx].call()


## ============================================================
##  精英敌人（3 个）
## ============================================================

## 葛叶 HP68：被动每回合+4护盾。风刃6×2 / 护体15 / 裂风掌15 / 虚弱2
static func create_elite_geye() -> Enemy:
	var enemy = Enemy.new("葛叶", 68)
	# 被动：每回合开始获得 4 护盾
	enemy.add_passive("turn_start", "gain_block", 4)

	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风刃")
	a1.damage = 6
	a1.hit_count = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "护体")
	a2.block = 15
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "裂风掌")
	a3.damage = 15
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "虚弱术")
	a4.apply_weak = 2
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 纳兰嫣然 HP90：被动首击-3。风灵剑14 / 护体10+易伤1 / 落日耀6×3 / 护山阵12+8
static func create_elite_nalan() -> Enemy:
	var enemy = Enemy.new("纳兰嫣然", 90)
	# 被动：每回合首次受击伤害 -3
	enemy.add_passive("turn_start", "first_hit_reduction", 3)

	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风灵剑")
	a1.damage = 14
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "护体")
	a2.block = 10
	a2.apply_vulnerable = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "落日耀")
	a3.damage = 6
	a3.hit_count = 3
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "护山阵")
	a4.block = 12
	a4.damage = 8
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 海波东 HP77：被动首击-4。冰封1 / 寒冰掌13 / 冰晶5×3 / 冰镜(18盾) / 玄冰刺20+冰封1
static func create_elite_hai_bodong() -> Enemy:
	var enemy = Enemy.new("海波东", 77)
	# 被动：每回合首次受击伤害 -4
	enemy.add_passive("turn_start", "first_hit_reduction", 4)

	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "冰封")
	a1.apply_frozen = 1
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "寒冰掌")
	a2.damage = 13
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "冰晶")
	a3.damage = 5
	a3.hit_count = 3
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "冰镜")
	a4.block = 18
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "玄冰刺")
	a5.damage = 20
	a5.apply_frozen = 1
	# 首轮冰封，之后循环回合2-5（设计文档：6+ 循环回合 2-5）
	enemy.first_action = a1
	enemy.set_actions([a2, a3, a4, a5])
	return enemy


## ============================================================
##  Boss：云山 HP162，2 阶段
## ============================================================

## 云山 HP162
## 阶段1（HP>50%）：护山阵15+脆弱2 / 风杀指12 / 落日耀6×3 / 宗主威压(塞2张风缠) / 循环+2力量
## 阶段2（HP≤50%）：风怒(清除debuff+力量2) / 岚灭25 / 万刃5×4 / 岚灭28 / 每2回合+1力量
static func create_boss_yunshan() -> Enemy:
	var enemy = Enemy.new("云山", 162)

	# 阶段 1 行动
	var p1_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "护山阵")
	p1_a1.block = 15
	p1_a1.apply_frail = 2
	var p1_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风杀指")
	p1_a2.damage = 12
	var p1_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "落日耀")
	p1_a3.damage = 6
	p1_a3.hit_count = 3
	var p1_a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "宗主威压")
	p1_a4.add_card_id = "wind_tangle"
	p1_a4.add_card_count = 2
	var phase1: Array[Enemy.EnemyAction] = [p1_a1, p1_a2, p1_a3, p1_a4]

	# 阶段 2 行动
	var p2_a1 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "风怒")
	p2_a1.clear_debuffs = true
	p2_a1.strength_gain = 2
	var p2_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "岚灭")
	p2_a2.damage = 25
	var p2_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "万刃")
	p2_a3.damage = 5
	p2_a3.hit_count = 4
	var p2_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "岚灭")
	p2_a4.damage = 28
	var p2_a5 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "蓄力")
	p2_a5.strength_gain = 1
	var phase2: Array[Enemy.EnemyAction] = [p2_a1, p2_a2, p2_a3, p2_a4, p2_a5]

	# HP <= 50% (81/162) 进入阶段 2
	enemy.set_phases([phase1, phase2], [0.5])

	return enemy


## ============================================================
##  战斗组合生成器
## ============================================================

## 创建普通战斗（1-3 个普通敌人）
static func create_normal_battle(floor: int = 0) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var count = 1 + RNGManager.monster_rng.randi() % 2  # 1-2 个敌人
	for i in range(count):
		enemies.append(create_random_normal_enemy(floor))
	return enemies


## 创建精英战斗（1 个精英敌人）
static func create_elite_battle() -> Array[Enemy]:
	var elites: Array[Callable] = [
		create_elite_geye,
		create_elite_nalan,
		create_elite_hai_bodong,
	]
	var idx = RNGManager.monster_rng.randi() % elites.size()
	return [elites[idx].call()]


## 创建 Boss 战斗
static func create_boss_battle() -> Array[Enemy]:
	return [create_boss_yunshan()]


## ============================================================
##  场景二：黑角域 — 普通敌人（7 个新增 + 1 个已有赏金猎人）
##  测试用数值：HP 25-38，攻击 5-8
## ============================================================

## 黑角域杀手 HP30：潜伏4盾+下回合攻击+3 / 暗影突袭8 / 双刺3×2
static func create_black_corner_assassin() -> Enemy:
	var enemy = Enemy.new("黑角域杀手", 30)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "潜伏")
	a1.block = 4
	a1.temp_strength = 3
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗影突袭")
	a2.damage = 8
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双刺")
	a3.damage = 3
	a3.hit_count = 2
	enemy.first_action = a1
	enemy.set_actions([a2, a3])
	return enemy


## 血宗弟子 HP32：血爪7 / 吸血5(回复等量) / 血爪7 / 血毒(蛇毒2)
static func create_blood_disciple() -> Enemy:
	var enemy = Enemy.new("血宗弟子", 32)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "血爪")
	a1.damage = 7
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "吸血")
	a2.damage = 5
	a2.heal = 5
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "血爪")
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "血毒")
	a4.apply_venom = 2
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 暗杀者组织成员 HP35：袖箭5×2 / 涂毒(虚弱1) / 暗杀10
static func create_assassin_member() -> Enemy:
	var enemy = Enemy.new("暗杀者组织成员", 35)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "袖箭")
	a1.damage = 5
	a1.hit_count = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "涂毒")
	a2.apply_weak = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗杀")
	a3.damage = 10
	enemy.set_actions([a1, a2, a3])
	return enemy


## 邪修炼药师 HP28：毒雾(蛇毒1+全体2盾) / 毒瓶6 / 自愈丹(回复8) / 麻药粉(冰封1)
static func create_heretical_alchemist() -> Enemy:
	var enemy = Enemy.new("邪修炼药师", 28)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒雾")
	a1.apply_venom = 1
	a1.block = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "毒瓶")
	a2.damage = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "自愈丹")
	a3.heal = 8
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "麻药粉")
	a4.apply_frozen = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 黑角域佣兵 HP38：铁壁6盾 / 重劈7 / 重劈7 / 破甲斩6+易伤1 / 狂斩4×2
static func create_black_corner_mercenary() -> Enemy:
	var enemy = Enemy.new("黑角域佣兵", 38)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "铁壁")
	a1.block = 6
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "重劈")
	a2.damage = 7
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "重劈")
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "破甲斩")
	a4.damage = 6
	a4.apply_vulnerable = 1
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "狂斩")
	a5.damage = 4
	a5.hit_count = 2
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 天蛇府刺客 HP25：毒牙6+蛇毒1 / 缠绕(虚弱1) / 剧毒5
static func create_serpent_assassin() -> Enemy:
	var enemy = Enemy.new("天蛇府刺客", 25)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒牙")
	a1.damage = 6
	a1.apply_venom = 1
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "缠绕")
	a2.apply_weak = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "剧毒")
	a3.damage = 5
	enemy.set_actions([a1, a2, a3])
	return enemy


## 天蛇府精锐刺客 HP35：猛毒噬咬8+蛇毒2 / 蛇皮硬化6盾 / 毒液喷射7+蛇毒1+虚弱1
static func create_serpent_elite_assassin() -> Enemy:
	var enemy = Enemy.new("天蛇府精锐刺客", 35)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "猛毒噬咬")
	a1.damage = 8
	a1.apply_venom = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "蛇皮硬化")
	a2.block = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "毒液喷射")
	a3.damage = 7
	a3.apply_venom = 1
	a3.apply_weak = 1
	enemy.set_actions([a1, a2, a3])
	return enemy


## ============================================================
##  场景二：黑角域 — 精英敌人（3 个）
##  测试用数值：HP 40-80，攻击 6-12
## ============================================================

## 范痨 HP80：被动回合开始回复3HP。血爪撕裂10+回3 / 血毒雾(蛇毒2) / 血海涌12+回4 / 血祭(回12+清debuff) / 双血爪6×2+回2×2
static func create_elite_fan_lao() -> Enemy:
	var enemy = Enemy.new("范痨", 80)
	enemy.add_passive("turn_start", "heal", 3)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "血爪撕裂")
	a1.damage = 10
	a1.heal = 3
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "血毒雾")
	a2.apply_venom = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "血海涌")
	a3.damage = 12
	a3.heal = 4
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "血祭")
	a4.heal = 12
	a4.clear_debuffs = true
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双血爪")
	a5.damage = 6
	a5.hit_count = 2
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 莫天行 HP75：被动回合开始获得1临时力量。黑帝印10 / 宗主威压(脆弱1+6盾) / 碎天12 / 黑帝双掌6×2 / 空间封锁(8盾+虚弱1)
static func create_elite_mo_tianxing() -> Enemy:
	var enemy = Enemy.new("莫天行", 75)
	enemy.add_passive("turn_start", "gain_strength", 1)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "黑帝印")
	a1.damage = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "宗主威压")
	a2.apply_frail = 1
	a2.block = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "碎天")
	a3.damage = 12
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "黑帝双掌")
	a4.damage = 6
	a4.hit_count = 2
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "空间封锁")
	a5.block = 8
	a5.apply_weak = 1
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 金老 HP40：金掌6 / 金银盾5 / 掌风交叉4×3 / 微青气10+虚弱
static func create_elite_gold_elder() -> Enemy:
	var enemy = Enemy.new("金老", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "金掌")
	a1.damage = 6
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "金银盾")
	a2.block = 5
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "掌风交叉")
	a3.damage = 4
	a3.hit_count = 3
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "微青气")
	a4.damage = 10
	a4.apply_weak = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 银老 HP40：银掌6 / 金银盾5 / 掌风交叉4×3 / 互补之力12+易伤
static func create_elite_silver_elder() -> Enemy:
	var enemy = Enemy.new("银老", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "银掌")
	a1.damage = 6
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "金银盾")
	a2.block = 5
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "掌风交叉")
	a3.damage = 4
	a3.hit_count = 3
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "互补之力")
	a4.damage = 12
	a4.apply_vulnerable = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## ============================================================
##  场景二：黑角域 — Boss：韩枫 HP150，3 阶段
##  测试用数值
## ============================================================

## 韩枫 HP150
## 阶段1（HP>100）：异火反噬10 / 炼药(回15+清debuff) / 灵魂冲击6+弃1牌 / 海心焰爆8
## 阶段2（HP50-100）：海心焰域(燃烧2+10盾) / 双焰掌8×2 / 秘药(回20) / 火莲碎片5×2+各1燃烧
## 阶段3（HP≤50）：燃血(清debuff+燃烧2+力量2) / 海心焰终12
static func create_boss_han_feng() -> Enemy:
	var enemy = Enemy.new("韩枫", 150)

	# 阶段 1 行动
	var p1_a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "异火反噬")
	p1_a1.damage = 10
	var p1_a2 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "炼药")
	p1_a2.heal = 15
	p1_a2.clear_debuffs = true
	var p1_a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "灵魂冲击")
	p1_a3.damage = 6
	p1_a3.add_card_id = "wind_tangle"
	p1_a3.add_card_count = 1
	var p1_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "海心焰爆")
	p1_a4.damage = 8
	var phase1: Array[Enemy.EnemyAction] = [p1_a1, p1_a2, p1_a3, p1_a4]

	# 阶段 2 行动
	var p2_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "海心焰域")
	p2_a1.apply_burn = 2
	p2_a1.block = 10
	var p2_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双焰掌")
	p2_a2.damage = 8
	p2_a2.hit_count = 2
	var p2_a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "秘药")
	p2_a3.heal = 20
	var p2_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "火莲碎片")
	p2_a4.damage = 5
	p2_a4.hit_count = 2
	var phase2: Array[Enemy.EnemyAction] = [p2_a1, p2_a2, p2_a3, p2_a4]

	# 阶段 3 行动
	var p3_a1 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "燃血")
	p3_a1.clear_debuffs = true
	p3_a1.strength_gain = 2
	var p3_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "海心焰终")
	p3_a2.damage = 12
	var phase3: Array[Enemy.EnemyAction] = [p3_a1, p3_a2]

	# HP <= 100 进入阶段2，HP <= 50 进入阶段3
	enemy.set_phases([phase1, phase2, phase3], [0.66, 0.34])

	return enemy


## ============================================================
##  场景二：黑角域 — 战斗组合生成器
## ============================================================

## 创建黑角域普通战斗
static func create_scene2_normal_battle(zone: int = 0) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var count = 1 + RNGManager.monster_rng.randi() % 2  # 1-2 个敌人
	for i in range(count):
		enemies.append(create_scene2_random_normal(zone))
	return enemies


## 黑角域随机普通敌人（按区域）
static func create_scene2_random_normal(zone: int = 0) -> Enemy:
	var factories: Array[Callable] = []
	# 子区域1（黑印城）：黑角域杀手、暗杀者组织成员、黑角域佣兵
	factories.append(create_black_corner_assassin)
	factories.append(create_assassin_member)
	factories.append(create_black_corner_mercenary)
	# 子区域2（血宗禁地）：+ 血宗弟子、邪修炼药师
	if zone >= 1:
		factories.append(create_blood_disciple)
		factories.append(create_heretical_alchemist)
	# 子区域3（枫城）：+ 天蛇府刺客、天蛇府精锐刺客
	if zone >= 2:
		factories.append(create_serpent_assassin)
		factories.append(create_serpent_elite_assassin)
	var idx = RNGManager.monster_rng.randi() % factories.size()
	return factories[idx].call()


## 创建黑角域精英战斗（含双人精英）
static func create_scene2_elite_battle() -> Array[Enemy]:
	var roll = RNGManager.monster_rng.randi() % 3
	match roll:
		0: return [create_elite_fan_lao()]
		1: return [create_elite_mo_tianxing()]
		_: return [create_elite_gold_elder(), create_elite_silver_elder()]  # 双人精英


## 创建黑角域 Boss 战斗
static func create_scene2_boss_battle() -> Array[Enemy]:
	return [create_boss_han_feng()]


## ============================================================
##  场景三：迦南学院 — 普通敌人（6 个）
##  测试用数值：HP 25-40，攻击 5-10
## ============================================================

## 外院弟子 HP30：斗技攻击7 / 修炼护体6盾 / 斗技攻击7 / 联合施压(虚弱1)
static func create_canaan_outer_disciple() -> Enemy:
	var enemy = Enemy.new("外院弟子", 30)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斗技攻击")
	a1.damage = 7
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "修炼护体")
	a2.block = 6
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斗技攻击")
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "联合施压")
	a4.apply_weak = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 内院精英弟子 HP35：内院斗技8 / 内院斗技8 / 攻防一体(4盾+6伤) / 绝技10
static func create_canaan_inner_disciple() -> Enemy:
	var enemy = Enemy.new("内院精英弟子", 35)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "内院斗技")
	a1.damage = 8
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "内院斗技")
	a2.damage = 8
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "攻防一体")
	a3.block = 4
	a3.damage = 6
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "绝技")
	a4.damage = 10
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 远古火蜥蜴 HP38：火焰吐息8+燃烧1 / 岩浆护甲7盾 / 火焰吐息8+燃烧1 / 熔岩爆裂10+燃烧2
static func create_ancient_fire_lizard() -> Enemy:
	var enemy = Enemy.new("远古火蜥蜴", 38)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "火焰吐息")
	a1.damage = 8
	a1.apply_burn = 1
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "岩浆护甲")
	a2.block = 7
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "火焰吐息")
	a3.damage = 8
	a3.apply_burn = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "熔岩爆裂")
	a4.damage = 10
	a4.apply_burn = 2
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 走火入魔者 HP32：疯狂乱击4×3 / 心魔爆发(虚弱1+易伤1) / 自爆前兆(5盾) / 走火入魔·爆12(自身受5伤)
static func create_cultivation_deviation() -> Enemy:
	var enemy = Enemy.new("走火入魔者", 32)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "疯狂乱击")
	a1.damage = 4
	a1.hit_count = 3
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "心魔爆发")
	a2.apply_weak = 1
	a2.apply_vulnerable = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "自爆前兆")
	a3.block = 5
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "走火入魔·爆")
	a4.damage = 12
	a4.self_damage = 5
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 心炎幻影 HP35：心火灼烧(燃烧2) / 心炎之击9 / 心魔窥探(塞1张心魔) / 心炎爆发(燃烧层数×3伤)
static func create_heart_flame_phantom() -> Enemy:
	var enemy = Enemy.new("心炎幻影", 35)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "心火灼烧")
	a1.apply_burn = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "心炎之击")
	a2.damage = 9
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "心魔窥探")
	a3.add_card_id = "inner_demon"
	a3.add_card_count = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "心炎爆发")
	a4.damage = 0
	a4.damage_per_burn_stack = 3
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 内院森林高阶魔兽 HP40：怒吼(6盾+虚弱1) / 巨掌拍击7 / 巨掌拍击7 / 狂暴冲撞10 / 怒吼(7盾)
static func create_forest_beast() -> Enemy:
	var enemy = Enemy.new("内院森林高阶魔兽", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "怒吼")
	a1.block = 6
	a1.apply_weak = 1
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "巨掌拍击")
	a2.damage = 7
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "巨掌拍击")
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "狂暴冲撞")
	a4.damage = 10
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "怒吼")
	a5.block = 7
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## ============================================================
##  场景三：迦南学院 — 精英敌人（3 个）
##  测试用数值：HP 60-100，攻击 8-15
## ============================================================

## 林修崖 HP80：被动回合开始3盾。风刃连斩5×2 / 疾风斩12 / 风压(虚弱1+易伤1+8伤) / 风之极·岚切15 / 风壁反击(7盾)
static func create_elite_lin_xiuya() -> Enemy:
	var enemy = Enemy.new("林修崖", 80)
	enemy.add_passive("turn_start", "gain_block", 3)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风刃连斩")
	a1.damage = 5
	a1.hit_count = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "疾风斩")
	a2.damage = 12
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "风压")
	a3.damage = 8
	a3.apply_weak = 1
	a3.apply_vulnerable = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "风之极·岚切")
	a4.damage = 15
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "风壁反击")
	a5.block = 7
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 柳擎 HP90：山岳护体10盾 / 山岳拳10 / 铁壁12盾 / 山崩地裂12+脆弱1 / 连山拳6×2
static func create_elite_liu_qing() -> Enemy:
	var enemy = Enemy.new("柳擎", 90)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "山岳护体")
	a1.block = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "山岳拳")
	a2.damage = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "铁壁")
	a3.block = 12
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "山崩地裂")
	a4.damage = 12
	a4.apply_frail = 1
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "连山拳")
	a5.damage = 6
	a5.hit_count = 2
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 地魔老鬼 HP85：暗影掌10 / 暗影缠绕(虚弱1+燃烧1) / 暗影爆裂15 / 灵魂侵蚀(虚弱2+燃烧2) / 召唤+攻击(5伤)
static func create_elite_earth_devil() -> Enemy:
	var enemy = Enemy.new("地魔老鬼", 85)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗影掌")
	a1.damage = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "暗影缠绕")
	a2.apply_weak = 1
	a2.apply_burn = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗影爆裂")
	a3.damage = 15
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂侵蚀")
	a4.apply_weak = 2
	a4.apply_burn = 2
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "召唤+攻击")
	a5.damage = 5
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 紫妍 HP75：强榜第一，太虚古龙族，肉身强悍
static func create_elite_ziyan() -> Enemy:
	var enemy = Enemy.new("紫妍", 75)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "内院绝技")
	a1.damage = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "威压震慑")
	a2.apply_weak = 1
	a2.apply_frail = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "破甲一击")
	a3.damage = 10
	a3.apply_vulnerable = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双连斩")
	a4.damage = 7
	a4.hit_count = 2
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "内院护体")
	a5.block = 7
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 韩月 HP65：强榜第九，韩枫之妹，风属性斗气
static func create_elite_han_yue() -> Enemy:
	var enemy = Enemy.new("韩月", 65)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "连环斩")
	a1.damage = 5
	a1.hit_count = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "疾风刺")
	a2.damage = 8
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "攻守兼备")
	a3.block = 5
	a3.damage = 7
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "绝影斩")
	a4.damage = 12
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 禁地守卫 HP100：封印结界12盾 / 禁制反击12 / 结界加固(10盾+脆弱1) / 封印解放(清盾×1.5伤) / 重新封印(7盾+回5)
static func create_elite_forbidden_guard() -> Enemy:
	var enemy = Enemy.new("禁地守卫", 100)
	enemy.add_passive("turn_start", "gain_block", 3)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "封印结界")
	a1.block = 12
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "禁制反击")
	a2.damage = 12
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "结界加固")
	a3.block = 10
	a3.apply_frail = 1
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "封印解放")
	a4.clear_player_block_mult = 1.5
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "重新封印")
	a5.block = 7
	a5.heal = 5
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## ============================================================
##  场景三：迦南学院 — Boss：陨落心炎 HP150，3 阶段
##  测试用数值
## ============================================================

## 陨落心炎 HP150
## 阶段1（HP>100）：心火弥漫(燃烧2) / 心炎之触10 / 心火分身(召唤) / 双炎击6×2+各1燃烧
## 阶段2（HP50-100）：心火风暴(燃烧3+力量2) / 心炎巨浪15 / 心火分身×2 / 三炎连击5×3
## 阶段3（HP≤50）：焚天(燃烧4+15伤) / 心火军团×3 / 心炎灭世20 / 五炎连爆4×5
static func create_boss_fallen_heart_flame() -> Enemy:
	var enemy = Enemy.new("陨落心炎", 150)

	# 阶段 1 行动
	var p1_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "心火弥漫")
	p1_a1.apply_burn = 2
	var p1_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "心炎之触")
	p1_a2.damage = 10
	var p1_a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "心火分身")
	p1_a3.strength_gain = 1
	var p1_a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "双炎击")
	p1_a4.damage = 6
	p1_a4.hit_count = 2
	var phase1: Array[Enemy.EnemyAction] = [p1_a1, p1_a2, p1_a3, p1_a4]

	# 阶段 2 行动
	var p2_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "心火风暴")
	p2_a1.apply_burn = 3
	p2_a1.strength_gain = 2
	var p2_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "心炎巨浪")
	p2_a2.damage = 15
	var p2_a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "心火分身")
	p2_a3.strength_gain = 2
	var p2_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "三炎连击")
	p2_a4.damage = 5
	p2_a4.hit_count = 3
	var phase2: Array[Enemy.EnemyAction] = [p2_a1, p2_a2, p2_a3, p2_a4]

	# 阶段 3 行动
	var p3_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "焚天")
	p3_a1.apply_burn = 4
	p3_a1.damage = 15
	var p3_a2 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "心火军团")
	p3_a2.strength_gain = 3
	var p3_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "心炎灭世")
	p3_a3.damage = 20
	var p3_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "五炎连爆")
	p3_a4.damage = 4
	p3_a4.hit_count = 5
	var phase3: Array[Enemy.EnemyAction] = [p3_a1, p3_a2, p3_a3, p3_a4]

	# HP <= 100 进入阶段2，HP <= 50 进入阶段3
	enemy.set_phases([phase1, phase2, phase3], [0.66, 0.34])

	return enemy


## ============================================================
##  场景三：迦南学院 — 战斗组合生成器
## ============================================================

## 创建迦南学院普通战斗
static func create_scene3_normal_battle(zone: int = 0) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var count = 1 + RNGManager.monster_rng.randi() % 2
	for i in range(count):
		enemies.append(create_scene3_random_normal(zone))
	return enemies


## 迦南学院随机普通敌人（按区域）
static func create_scene3_random_normal(zone: int = 0) -> Enemy:
	var factories: Array[Callable] = []
	# 子区域1（外院）：外院弟子、内院精英弟子
	factories.append(create_canaan_outer_disciple)
	factories.append(create_canaan_inner_disciple)
	# 子区域2（内院）：+ 远古火蜥蜴、走火入魔者
	if zone >= 1:
		factories.append(create_ancient_fire_lizard)
		factories.append(create_cultivation_deviation)
	# 子区域3（天焚炼气塔底层）：+ 心炎幻影、内院森林高阶魔兽
	if zone >= 2:
		factories.append(create_heart_flame_phantom)
		factories.append(create_forest_beast)
	var idx = RNGManager.monster_rng.randi() % factories.size()
	return factories[idx].call()


## 创建迦南学院精英战斗
static func create_scene3_elite_battle() -> Array[Enemy]:
	var elites: Array[Callable] = [
		create_elite_lin_xiuya,
		create_elite_liu_qing,
		create_elite_earth_devil,
	]
	var idx = RNGManager.monster_rng.randi() % elites.size()
	return [elites[idx].call()]


## 创建迦南学院 Boss 战斗
static func create_scene3_boss_battle() -> Array[Enemy]:
	return [create_boss_fallen_heart_flame()]


## ============================================================
##  场景四：中州 — 普通敌人（7 个）
##  测试用数值：HP 35-50，攻击 8-12
## ============================================================

## 魂殿护卫 HP40：灵魂护盾7盾 / 魂刃10 / 魂刃10 / 灵魂压制(虚弱1+脆弱1)
static func create_soul_hall_guard() -> Enemy:
	var enemy = Enemy.new("魂殿护卫", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "灵魂护甲")
	a1.block = 7
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	a2.damage = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	a3.damage = 10
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂压制")
	a4.apply_weak = 1
	a4.apply_frail = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 暗魂使者 HP45：暗影标记(易伤2) / 暗魂斩10 / 暗魂斩10 / 灵魂侵蚀(塞灵魂创伤)
static func create_dark_soul_messenger() -> Enemy:
	var enemy = Enemy.new("暗魂使者", 45)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "暗影标记")
	a1.apply_vulnerable = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗魂斩")
	a2.damage = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "暗魂斩")
	a3.damage = 10
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂侵蚀")
	a4.add_card_id = "soul_trauma"
	a4.add_card_count = 1
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 魂殿长老 HP50：魂掌12 / 灵魂锁链(冰封1) / 魂盾9盾 / 灵魂震爆12 / 灵魂汲取8+回8
static func create_soul_hall_elder() -> Enemy:
	var enemy = Enemy.new("魂殿长老", 50)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂掌")
	a1.damage = 12
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂锁链")
	a2.apply_frozen = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "魂盾")
	a3.block = 9
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂震爆")
	a4.damage = 12
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "灵魂汲取")
	a5.damage = 8
	a5.heal = 8
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 远古傀儡 HP50：远古护盾10盾 / 重拳10 / 重拳10 / 毁灭光束15 / 自我修复(回10+7盾)
static func create_ancient_puppet() -> Enemy:
	var enemy = Enemy.new("远古傀儡", 50)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "远古护盾")
	a1.block = 10
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "重拳")
	a2.damage = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "重拳")
	a3.damage = 10
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "毁灭光束")
	a4.damage = 15
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "自我修复")
	a5.heal = 10
	a5.block = 7
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 古族战士 HP45：古族斗技11 / 古族斗技11 / 血脉觉醒(力量2) / 古族绝技12 / 攻守兼备(6盾+9伤)
static func create_ancient_clan_warrior() -> Enemy:
	var enemy = Enemy.new("古族战士", 45)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "古族斗技")
	a1.damage = 11
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "古族斗技")
	a2.damage = 11
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "血脉觉醒")
	a3.strength_gain = 2
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "古族绝技")
	a4.damage = 12
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "攻守兼备")
	a5.block = 6
	a5.damage = 9
	enemy.set_actions([a1, a2, a3, a4, a5])
	return enemy


## 灵魂虚影 HP38：灵魂穿刺8 / 灵魂共鸣(虚弱2) / 灵魂穿刺8 / 灵魂爆裂12
static func create_soul_phantom() -> Enemy:
	var enemy = Enemy.new("灵魂虚影", 38)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂穿刺")
	a1.damage = 8
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂共鸣")
	a2.apply_weak = 2
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂穿刺")
	a3.damage = 8
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂爆裂")
	a4.damage = 12
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## 丹塔守卫 HP45：药鼎护体7盾 / 丹火掌10 / 丹火掌10 / 药火爆发12+燃烧2
static func create_pill_tower_guard() -> Enemy:
	var enemy = Enemy.new("丹塔守卫", 45)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "药鼎护体")
	a1.block = 7
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "丹火掌")
	a2.damage = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "丹火掌")
	a3.damage = 10
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "药火爆发")
	a4.damage = 12
	a4.apply_burn = 2
	enemy.set_actions([a1, a2, a3, a4])
	return enemy


## ============================================================
##  场景四：中州 — 精英敌人（4 个）
##  测试用数值：HP 80-120，攻击 10-18
## ============================================================

## 药丹 HP100：药火掌12 / 药鼎护体10盾 / 炼药(回15) / 药火焚天18+燃烧2 / 药雾(虚弱2+脆弱2) / 双火掌8×2
static func create_elite_yao_dan() -> Enemy:
	var enemy = Enemy.new("药丹", 100)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "药火掌")
	a1.damage = 12
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "药鼎护体")
	a2.block = 10
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "炼药")
	a3.heal = 15
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "药火焚天")
	a4.damage = 18
	a4.apply_burn = 2
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "药雾")
	a5.apply_weak = 2
	a5.apply_frail = 2
	var a6 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双火掌")
	a6.damage = 8
	a6.hit_count = 2
	enemy.set_actions([a1, a2, a3, a4, a5, a6])
	return enemy


## 魂灭生 HP120：魂刃风暴8×2 / 灵魂锁链(虚弱1+冰封1) / 魂灭斩18 / 三魂连击6×3 / 灵魂风暴15+易伤2 / 魂刃12
static func create_elite_hun_miesheng() -> Enemy:
	var enemy = Enemy.new("魂灭生", 120)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃风暴")
	a1.damage = 8
	a1.hit_count = 2
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂锁链")
	a2.apply_weak = 1
	a2.apply_frozen = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂灭斩")
	a3.damage = 18
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "三魂连击")
	a4.damage = 6
	a4.hit_count = 3
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "灵魂风暴")
	a5.damage = 15
	a5.apply_vulnerable = 2
	var a6 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	a6.damage = 12
	enemy.set_actions([a1, a2, a3, a4, a5, a6])
	return enemy


## 血河·魂殿四天尊（攻击型）HP50：魂掌8 / 魂爆12
static func create_soul_elder_a() -> Enemy:
	var enemy = Enemy.new("血河", 50)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂掌")
	a1.damage = 8
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂爆")
	a2.damage = 12
	enemy.set_actions([a1, a2])
	return enemy


## 硕武·魂殿三天尊（防御型）HP50：魂盾5盾(全体) / 魂盾5盾(全体) / 魂刃6
static func create_soul_elder_b() -> Enemy:
	var enemy = Enemy.new("硕武", 50)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "魂盾")
	a1.block = 5
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "魂盾")
	a2.block = 5
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	a3.damage = 6
	enemy.set_actions([a1, a2, a3])
	return enemy


## 魔雨·魂殿九天尊（控制型）HP50：灵魂压制(虚弱1) / 灵魂锁链(冰封1) / 魂掌8
static func create_soul_elder_c() -> Enemy:
	var enemy = Enemy.new("魔雨", 50)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂压制")
	a1.apply_weak = 1
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂锁链")
	a2.apply_frozen = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂掌")
	a3.damage = 8
	enemy.set_actions([a1, a2, a3])
	return enemy


## 骨幽·魂殿二天尊（辅助型）HP40：灵魂链接(回5) / 魂刃5 / 灵魂增幅(力量1)
static func create_soul_elder_d() -> Enemy:
	var enemy = Enemy.new("骨幽", 40)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "灵魂链接")
	a1.heal = 5
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	a2.damage = 5
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "灵魂增幅")
	a3.strength_gain = 1
	enemy.set_actions([a1, a2, a3])
	return enemy


## 魂殿尊老（事件精英）HP100：灵魂收割12 / 灵魂锁链(冰封1+虚弱1) / 魂灭斩18 / 魂盾10盾 / 双魂连击9×2 / 灵魂汲取10+回10
static func create_elite_soul_hall_elder() -> Enemy:
	var enemy = Enemy.new("魂殿尊老", 100)
	enemy.add_passive("turn_start", "first_hit_reduction", 3)
	var a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂收割")
	a1.damage = 12
	var a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂锁链")
	a2.apply_frozen = 1
	a2.apply_weak = 1
	var a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂灭斩")
	a3.damage = 18
	var a4 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "魂盾")
	a4.block = 10
	var a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双魂连击")
	a5.damage = 9
	a5.hit_count = 2
	var a6 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "灵魂汲取")
	a6.damage = 10
	a6.heal = 10
	enemy.set_actions([a1, a2, a3, a4, a5, a6])
	return enemy


## ============================================================
##  场景四：中州 — Boss：魂天帝 HP250，5 阶段
##  测试用数值
## ============================================================

## 魂天帝 HP250
static func create_boss_huntiandi() -> Enemy:
	var enemy = Enemy.new("魂天帝", 250)

	# 阶段 1（HP>200）：血之帝身
	var p1_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "血之帝身")
	p1_a1.block = 15
	p1_a1.apply_weak = 1
	p1_a1.apply_vulnerable = 1
	var p1_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斩帝鬼血刃")
	p1_a2.damage = 5
	p1_a2.hit_count = 3
	var p1_a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "虚无吞炎")
	p1_a3.add_card_id = "swallow"
	p1_a3.add_card_count = 1
	var p1_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "魂刃")
	p1_a4.damage = 12
	var phase1: Array[Enemy.EnemyAction] = [p1_a1, p1_a2, p1_a3, p1_a4]

	# 阶段 2（HP 160-200）：万魂归一
	var p2_a1 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "万魂召唤")
	p2_a1.strength_gain = 2
	var p2_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "万魔噬心")
	p2_a2.damage = 18
	var p2_a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂风暴")
	p2_a3.apply_weak = 2
	p2_a3.apply_vulnerable = 2
	var p2_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "三魂连击")
	p2_a4.damage = 6
	p2_a4.hit_count = 3
	var phase2: Array[Enemy.EnemyAction] = [p2_a1, p2_a2, p2_a3, p2_a4]

	# 阶段 3（HP 100-160）：虚无吞炎
	var p3_a1 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "虚无吞炎·领域")
	p3_a1.apply_burn = 3
	p3_a1.damage = 12
	var p3_a2 = Enemy.EnemyAction.new(Enemy.IntentType.DEFEND, "虚无护盾")
	p3_a2.block = 12
	var p3_a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "虚无吞炎·吞噬")
	p3_a3.damage = 20
	p3_a3.heal = 8
	var p3_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双魂刃")
	p3_a4.damage = 10
	p3_a4.hit_count = 2
	var phase3: Array[Enemy.EnemyAction] = [p3_a1, p3_a2, p3_a3, p3_a4]

	# 阶段 4（HP 50-100）：帝境全开
	var p4_a1 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "帝境威压")
	p4_a1.apply_weak = 1
	p4_a1.apply_vulnerable = 1
	p4_a1.apply_frail = 1
	var p4_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斩帝鬼血刃·极")
	p4_a2.damage = 5
	p4_a2.hit_count = 3
	var p4_a3 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "吞噬生机")
	p4_a3.damage = 15
	p4_a3.heal = 15
	var p4_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "四魂连爆")
	p4_a4.damage = 6
	p4_a4.hit_count = 4
	var phase4: Array[Enemy.EnemyAction] = [p4_a1, p4_a2, p4_a3, p4_a4]

	# 阶段 5（HP≤50）：斗帝残念
	var p5_a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斗帝一击")
	p5_a1.damage = 18
	var p5_a2 = Enemy.EnemyAction.new(Enemy.IntentType.SPECIAL, "灵魂崩碎")
	p5_a2.apply_burn = 2
	p5_a2.apply_vulnerable = 1
	p5_a2.block = 6
	var p5_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "斩帝鬼血刃·终")
	p5_a3.damage = 18
	var p5_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双魂连击")
	p5_a4.damage = 8
	p5_a4.hit_count = 2
	var phase5: Array[Enemy.EnemyAction] = [p5_a1, p5_a2, p5_a3, p5_a4]

	# 阶段阈值：80%, 64%, 40%, 20%
	enemy.set_phases([phase1, phase2, phase3, phase4, phase5], [0.8, 0.64, 0.4, 0.2])

	return enemy


## 隐藏Boss：古帝残魂（HP 600，3阶段）
## 触发方式：事件链「古帝之谜」→ 场景四强制事件42
static func create_boss_ancient_emperor_soul() -> Enemy:
	var enemy = Enemy.new("古帝残魂", 600)

	# 阶段 1（HP>400）：帝境余威
	var p1_a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "帝威冲击")
	p1_a1.damage = 20
	p1_a1.apply_vulnerable = 1
	var p1_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "帝威冲击")
	p1_a2.damage = 22
	p1_a2.apply_vulnerable = 1
	var p1_a3 = Enemy.EnemyAction.new(Enemy.IntentType.DEBUFF, "灵魂压制")
	p1_a3.apply_weak = 2
	p1_a3.apply_frail = 2
	var p1_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "帝境一击")
	p1_a4.damage = 25
	p1_a4.apply_vulnerable = 1
	var phase1: Array[Enemy.EnemyAction] = [p1_a1, p1_a2, p1_a3, p1_a4]

	# 阶段 2（HP 200-400）：灵魂觉醒
	var p2_a1 = Enemy.EnemyAction.new(Enemy.IntentType.BUFF, "灵魂增幅")
	p2_a1.strength_gain = 1
	var p2_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂风暴")
	p2_a2.damage = 30
	var p2_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂风暴")
	p2_a3.damage = 32
	var p2_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "双魂击")
	p2_a4.damage = 16
	p2_a4.hit_count = 2
	var p2_a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灵魂震爆")
	p2_a5.damage = 35
	var phase2: Array[Enemy.EnemyAction] = [p2_a1, p2_a2, p2_a3, p2_a4, p2_a5]

	# 阶段 3（HP≤200）：帝境压制
	var p3_a1 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "帝境压制")
	p3_a1.damage = 50
	var p3_a2 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灭魂冲击")
	p3_a2.damage = 40
	var p3_a3 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灭魂冲击")
	p3_a3.damage = 45
	var p3_a4 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "帝境压制")
	p3_a4.damage = 50
	var p3_a5 = Enemy.EnemyAction.new(Enemy.IntentType.ATTACK, "灭魂冲击")
	p3_a5.damage = 45
	var phase3: Array[Enemy.EnemyAction] = [p3_a1, p3_a2, p3_a3, p3_a4, p3_a5]

	# 阶段阈值：67%, 33%
	enemy.set_phases([phase1, phase2, phase3], [0.67, 0.33])

	return enemy


## ============================================================
##  场景四：中州 — 战斗组合生成器
## ============================================================

## 创建中州普通战斗
static func create_scene4_normal_battle(zone: int = 0) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var count = 1 + RNGManager.monster_rng.randi() % 2
	for i in range(count):
		enemies.append(create_scene4_random_normal(zone))
	return enemies


## 中州随机普通敌人（按区域）
static func create_scene4_random_normal(zone: int = 0) -> Enemy:
	var factories: Array[Callable] = []
	# 子区域1（丹塔）：魂殿护卫、丹塔守卫
	factories.append(create_soul_hall_guard)
	factories.append(create_pill_tower_guard)
	# 子区域2（魂殿）：+ 暗魂使者、魂殿长老
	if zone >= 1:
		factories.append(create_dark_soul_messenger)
		factories.append(create_soul_hall_elder)
	# 子区域3（古帝洞府）：+ 远古傀儡、古族战士、灵魂虚影
	if zone >= 2:
		factories.append(create_ancient_puppet)
		factories.append(create_ancient_clan_warrior)
		factories.append(create_soul_phantom)
	var idx = RNGManager.monster_rng.randi() % factories.size()
	return factories[idx].call()


## 创建中州精英战斗
static func create_scene4_elite_battle() -> Array[Enemy]:
	var elites: Array[Callable] = [
		create_elite_yao_dan,
		create_elite_hun_miesheng,
	]
	var idx = RNGManager.monster_rng.randi() % elites.size()
	return [elites[idx].call()]


## 创建中州 Boss 战斗
static func create_scene4_boss_battle() -> Array[Enemy]:
	return [create_boss_huntiandi()]
