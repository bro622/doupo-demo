// Auto-generated event data
const EVENTS = [
  {
    "file": "floor_zero_event.gd",
    "scene_dir": "root",
    "id": 0,
    "name": "菩提古树",
    "description": "远古菩提树下，一道苍老的声音在你心中响起...\\n",
    "category": "SPECIAL",
    "scene_id": 0,
    "character": "",
    "is_ancient": false,
    "is_forced": true,
    "choices": [
      {
        "text": "菩提恩赐",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 100,
            "ref": "",
            "desc": "恢复全部生命值"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          }
        ]
      },
      {
        "text": "菩提威压",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 100,
            "ref": "",
            "desc": "恢复全部生命值"
          },
          {
            "type": "FLAG",
            "value": 3,
            "ref": "floor_zero_battles",
            "desc": "接下来3场战斗敌人初始HP=1"
          }
        ]
      },
      {
        "text": "菩提试炼",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 100,
            "ref": "",
            "desc": "恢复全部生命值"
          },
          {
            "type": "MAX_HP",
            "value": -10,
            "ref": "",
            "desc": "失去10%最大HP"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "rare",
            "desc": "获得随机稀有遗物"
          }
        ]
      },
      {
        "text": "菩提洗髓",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 100,
            "ref": "",
            "desc": "恢复全部生命值"
          },
          {
            "type": "REMOVE_CARD",
            "value": 2,
            "ref": "basic",
            "desc": "移除2张基础牌"
          },
          {
            "type": "CARD",
            "value": 2,
            "ref": "advanced",
            "desc": "替换为2张进阶卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_bodhitree.png"
  },
  {
    "file": "event_mountain.gd",
    "scene_dir": "jia_ma",
    "id": 1,
    "name": "魔兽山脉的隐秘洞穴",
    "description": "你在魔兽山脉中发现了一个隐秘的洞穴，洞口散发着微弱的光芒。你决定如何行动？",
    "category": "PLOT",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "深入探索",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "mountain_beast",
            "desc": "遭遇洞穴守护魔兽！"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "击败后获得稀有卡牌"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "59",
            "desc": "获得遗物「七彩灵鹤羽」"
          },
          {
            "type": "CURSE_CARD",
            "value": 0,
            "ref": "beast_backlash",
            "desc": "受到兽性反噬..."
          }
        ]
      },
      {
        "text": "采集矿石",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 8,
            "ref": "",
            "desc": "洞穴碎石造成8点伤害"
          },
          {
            "type": "GOLD",
            "value": 120,
            "ref": "",
            "desc": "获得120金币的矿石"
          },
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "发现2瓶丹药"
          }
        ]
      },
      {
        "text": "悄然退走",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_cave.png"
  },
  {
    "file": "event_nalan.gd",
    "scene_dir": "jia_ma",
    "id": 2,
    "name": "纳兰嫣然的退婚",
    "description": "云岚宗弟子纳兰嫣然前来退婚，萧家颜面尽失。你将如何应对？",
    "category": "PLOT",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "隐忍接下",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币作为补偿"
          },
          {
            "type": "CURSE_CARD",
            "value": 0,
            "ref": "broken_engagement",
            "desc": "退婚之辱洗入牌库..."
          }
        ]
      },
      {
        "text": "莫欺少年穷",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "51",
            "desc": "获得遗物「三年之约」：每场战斗第1回合额外获得1点斗气并抽1张牌"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "three_year_promise",
            "desc": "设定「三年之约」标记"
          }
        ]
      },
      {
        "text": "以武证道",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "elite_nalan",
            "desc": "与纳兰嫣然战斗！"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "击败后获得稀有卡牌"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "three_year_promise",
            "desc": "宣告三年之约"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "yunshan_weakened",
            "desc": "云山被削弱"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_xiaohall.png"
  },
  {
    "file": "event_purple_crystal.gd",
    "scene_dir": "jia_ma",
    "id": 3,
    "name": "魔兽山脉的紫晶洞府",
    "description": "你在魔兽山脉深处发现了一个紫晶洞府，洞内紫晶能量浓郁，似乎蕴含着强大的火属性力量。",
    "category": "PLOT",
    "scene_id": 1,
    "character": "xiaoyan",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "运转焚诀吞噬",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "fire_combo",
            "desc": "领悟「异火连击」"
          },
          {
            "type": "CURSE_CARD",
            "value": 0,
            "ref": "beast_backlash",
            "desc": "吞噬过程中受到兽性反噬..."
          }
        ]
      },
      {
        "text": "小心刮取紫晶源",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "52",
            "desc": "获得遗物「紫晶源」：异火槽满载时回复2HP"
          },
          {
            "type": "DAMAGE",
            "value": 12,
            "ref": "",
            "desc": "紫晶能量灼伤，受到12点伤害"
          }
        ]
      },
      {
        "text": "悄然退走",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_purplecave.png"
  },
  {
    "file": "event_snake_pool.gd",
    "scene_dir": "jia_ma",
    "id": 4,
    "name": "蛇人族圣池",
    "description": "这是历代美杜莎女王蜕变的圣地，池水中蕴含着极度狂暴的能量。",
    "category": "PLOT",
    "scene_id": 1,
    "character": "cailin",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "沐浴毒液",
        "outcomes": [
          {
            "type": "UPGRADE_CARD",
            "value": 2,
            "ref": "",
            "desc": "毒液淬炼，2张卡牌获得升级"
          },
          {
            "type": "DAMAGE",
            "value": 12,
            "ref": "",
            "desc": "毒液侵蚀，受到12点伤害"
          }
        ]
      },
      {
        "text": "剥离软弱",
        "outcomes": [
          {
            "type": "REMOVE_CARD",
            "value": 2,
            "ref": "",
            "desc": "剥离了2张卡牌"
          },
          {
            "type": "DAMAGE",
            "value": 5,
            "ref": "",
            "desc": "剥离过程造成5点伤害"
          }
        ]
      },
      {
        "text": "吞天蟒之魂",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "shadow_lurk",
            "desc": "获得卡牌【暗影潜行】"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_snakepool.png"
  },
  {
    "file": "event_xiao_crisis.gd",
    "scene_dir": "jia_ma",
    "id": 5,
    "name": "萧家危机",
    "description": "萧家遭到不明势力袭击，情况危急。你必须做出选择。",
    "category": "COMBAT",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "挺身而出",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "xiao_raider",
            "desc": "与袭击者战斗！"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "5",
            "desc": "战斗胜利后获得遗物「萧家族徽」"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      },
      {
        "text": "暗中解决",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 8,
            "ref": "",
            "desc": "暗中交手受到8点伤害"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "寻求外援",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 80,
            "ref": "",
            "desc": "获得80金币援助"
          },
          {
            "type": "CURSE_CARD",
            "value": 0,
            "ref": "xiao_family_shame",
            "desc": "萧家耻辱洗入牌库..."
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_xiaocourtyard.png"
  },
  {
    "file": "event_desert_bandit.gd",
    "scene_dir": "jia_ma",
    "id": 6,
    "name": "塔戈尔沙漠劫匪",
    "description": "在塔戈尔沙漠中遭遇一伙劫匪，他们拦住了你的去路。",
    "category": "COMBAT",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "正面歼灭",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "desert_bandit",
            "desc": "与劫匪战斗！"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "1",
            "desc": "获得1瓶回气散"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      },
      {
        "text": "交钱买路",
        "outcomes": []
      },
      {
        "text": "反抢",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "desert_bandit_hard",
            "desc": "与劫匪精锐战斗！"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得1瓶丹药"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_desert_road.png"
  },
  {
    "file": "event_yunlan_ambush.gd",
    "scene_dir": "jia_ma",
    "id": 7,
    "name": "云岚宗弟子伏击",
    "description": "一伙云岚宗弟子埋伏在路边，似乎早就料到你会经过。",
    "category": "COMBAT",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "强攻突破",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "yunlan_ambush",
            "desc": "与云岚宗弟子战斗！"
          },
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "绕道而行",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 6,
            "ref": "",
            "desc": "绕行途中受到6点伤害"
          }
        ]
      },
      {
        "text": "以理服人",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "出示三年之约，对方让步，获得100金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_yunlan_ambush.png"
  },
  {
    "file": "event_auction.gd",
    "scene_dir": "jia_ma",
    "id": 8,
    "name": "米特尔拍卖行",
    "description": "米特尔拍卖行正在举行拍卖会，各种珍品琳琅满目。你可以选择竞拍或闲逛。",
    "category": "REWARD",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "浏览丹药",
        "outcomes": [
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "购买2瓶丹药"
          }
        ]
      },
      {
        "text": "浏览卡牌",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "购买1张稀有卡牌"
          }
        ]
      },
      {
        "text": "闲逛离开",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 30,
            "ref": "",
            "desc": "捡到30金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_auctionhouse.png"
  },
  {
    "file": "event_yao_lao.gd",
    "scene_dir": "jia_ma",
    "id": 9,
    "name": "药老的炼药指导",
    "description": "药尘药尊难得有兴致指导你的修炼，你希望向他学习什么？",
    "category": "REWARD",
    "scene_id": 1,
    "character": "xiaoyan",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "学习炼药术",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "11",
            "desc": "获得遗物「炼药手札」：选择休息时额外回复15HP"
          }
        ]
      },
      {
        "text": "请教战斗技巧",
        "outcomes": [
          {
            "type": "UPGRADE_CARD",
            "value": 1,
            "ref": "",
            "desc": "随机升级1张卡牌"
          }
        ]
      },
      {
        "text": "询问异火知识",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "fire_control",
            "desc": "获得卡牌「控火决」"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_yaohut.png"
  },
  {
    "file": "event_fire_snake.gd",
    "scene_dir": "jia_ma",
    "id": 10,
    "name": "沙漠地底的双头火灵蛇",
    "description": "在沙漠地底深处，你遇到了一条双头火灵蛇。它守护着珍贵的宝藏，但也极具攻击性。",
    "category": "RISK",
    "scene_id": 1,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "与蛇搏斗",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "fire_snake",
            "desc": "与双头火灵蛇战斗！"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "55",
            "desc": "击败后获得遗物「赤火蛇鳞」"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      },
      {
        "text": "用丹药引开",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "趁机取得稀有卡牌"
          },
          {
            "type": "GOLD",
            "value": 50,
            "ref": "",
            "desc": "获得50金币"
          }
        ]
      },
      {
        "text": "悄然退走",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_desertcave.png"
  },
  {
    "file": "event_auction_2.gd",
    "scene_dir": "black_corner",
    "id": 11,
    "name": "黑印城拍卖会",
    "description": "黑印城的地下拍卖会正在进行，各种珍稀物品琳琅满目。",
    "category": "PLOT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "购买地灵丹",
        "outcomes": [
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得地灵丹"
          }
        ]
      },
      {
        "text": "竞拍遗物",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "rare",
            "desc": "获得随机稀有遗物"
          }
        ]
      },
      {
        "text": "偷窃",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "auction_thieves",
            "desc": "击退盗贼"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "rare",
            "desc": "获得随机稀有遗物"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_dark_auction.png"
  },
  {
    "file": "event_hanfeng_trap.gd",
    "scene_dir": "black_corner",
    "id": 12,
    "name": "韩枫的陷阱",
    "description": "你发现了韩枫设下的陷阱，但似乎还有其他选择...",
    "category": "PLOT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "主动出击",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "han_feng_weakened",
            "desc": "与韩枫交战"
          }
        ]
      },
      {
        "text": "承受毒伤",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 20,
            "ref": "",
            "desc": "毒素侵蚀，受到20点伤害"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "忽略",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_hanfeng_trap.png"
  },
  {
    "file": "event_mystery_merchant.gd",
    "scene_dir": "black_corner",
    "id": 13,
    "name": "暗巷中的神秘商人",
    "description": "一个神秘的商人在暗巷中向你招手，他的斗篷下藏着各种奇异物品。",
    "category": "PLOT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "购买诅咒护符",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "53",
            "desc": "获得诅咒护符"
          }
        ]
      },
      {
        "text": "以命换牌",
        "outcomes": [
          {
            "type": "MAX_HP",
            "value": -10,
            "ref": "",
            "desc": "永久失去10点最大HP"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_mystery_merchant.png"
  },
  {
    "file": "event_blood_arena.gd",
    "scene_dir": "black_corner",
    "id": 14,
    "name": "血腥角斗场",
    "description": "黑印城的地下角斗场，鲜血与荣耀的交汇处。",
    "category": "COMBAT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "参加角斗",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "arena_fight_1",
            "desc": "参加角斗"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "赌博",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "赢得150金币"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "arena_gamble_curse",
            "desc": "下场战斗获得2张状态牌"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_blood_arena.png"
  },
  {
    "file": "event_assassin_ambush.gd",
    "scene_dir": "black_corner",
    "id": 15,
    "name": "暗杀者伏击",
    "description": "黑暗中传来窸窣声，你被暗杀者包围了！",
    "category": "COMBAT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "迎战",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "assassin_ambush_normal",
            "desc": "击退暗杀者"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "花钱消灾",
        "outcomes": []
      },
      {
        "text": "挑战模式",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "assassin_ambush_hard",
            "desc": "击败强化暗杀者"
          },
          {
            "type": "GOLD",
            "value": 300,
            "ref": "",
            "desc": "获得300金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有遗物"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_assassin_ambush.png"
  },
  {
    "file": "event_blood_sect_explore.gd",
    "scene_dir": "black_corner",
    "id": 16,
    "name": "血宗禁地探索",
    "description": "血宗禁地弥漫着浓重的血腥气息，前方隐约可见一座邪殿。",
    "category": "COMBAT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "深入探索",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "blood_sect_guard",
            "desc": "击退血宗守卫"
          },
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          }
        ]
      },
      {
        "text": "偷取秘典",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "CURSE_CARD",
            "value": 1,
            "ref": "blood_toxin_backlash",
            "desc": "获得诅咒牌血毒反噬"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_blood_sect_explore.png"
  },
  {
    "file": "event_serpent_outpost.gd",
    "scene_dir": "black_corner",
    "id": 17,
    "name": "天蛇府暗哨",
    "description": "天蛇府的暗哨隐藏在毒雾弥漫的枫城深处。",
    "category": "COMBAT",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "突袭暗哨",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "serpent_ambush",
            "desc": "击退天蛇府"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得高级药水"
          }
        ]
      },
      {
        "text": "潜入侦察",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 10,
            "ref": "",
            "desc": "被毒蛇咬伤，受到10点伤害"
          },
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "",
            "desc": "获得随机卡牌"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_serpent_nest.png"
  },
  {
    "file": "event_smuggler.gd",
    "scene_dir": "black_corner",
    "id": 18,
    "name": "走私商人",
    "description": "一个鬼鬼祟祟的走私商人向你展示他的货物。",
    "category": "REWARD",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "购买药水",
        "outcomes": [
          {
            "type": "POTION",
            "value": 3,
            "ref": "",
            "desc": "获得3个药水"
          }
        ]
      },
      {
        "text": "购买秘典",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_smuggler.png"
  },
  {
    "file": "event_alchemist_ruins.gd",
    "scene_dir": "black_corner",
    "id": 19,
    "name": "炼药师的遗迹",
    "description": "一座古老的炼药师遗迹出现在你面前，里面似乎还残留着丹药的气息。",
    "category": "REWARD",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "炼丹调息",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 30,
            "ref": "",
            "desc": "回复30%最大HP"
          }
        ]
      },
      {
        "text": "搜刮遗物",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得普通遗物"
          }
        ]
      },
      {
        "text": "炼制秘药",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 30,
            "ref": "",
            "desc": "消耗精血，失去30点生命值"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得高级药水"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_alchemist_ruins.png"
  },
  {
    "file": "event_dark_auction.gd",
    "scene_dir": "black_corner",
    "id": 20,
    "name": "暗黑拍卖会",
    "description": "一场神秘的地下拍卖会，拍卖的物品都是禁忌之物。",
    "category": "RISK",
    "scene_id": 2,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "竞拍禁忌之书",
        "outcomes": [
          {
            "type": "MAX_HP",
            "value": -15,
            "ref": "",
            "desc": "永久失去15点最大HP"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说卡牌"
          }
        ]
      },
      {
        "text": "竞拍遗物",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 15,
            "ref": "",
            "desc": "失去15点HP"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "epic",
            "desc": "获得史诗遗物"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_dark_auction.png"
  },
  {
    "file": "event_ancient_scene2.gd",
    "scene_dir": "ancient",
    "id": 100,
    "name": "守灵",
    "description": "",
    "category": "SPECIAL",
    "scene_id": 2,
    "character": "",
    "is_ancient": true,
    "is_forced": false,
    "choices": [],
    "character_options": {
      "xiaoyan": [
        "药老指点·净心",
        "药老指点·炼体",
        "药老指点·备药"
      ],
      "xuner": [
        "古族洗礼·净脉",
        "古族秘法·觉醒",
        "古族遗宝·灵药"
      ],
      "cailin": [
        "蛇族淬体·蜕鳞",
        "蛇族秘术·噬血",
        "蛇族遗蜕·蛇胆"
      ]
    },
    "character_dialogs": {
      "xiaoyan": "药尘的声音从纳戒中传来，语气罕见地凝重——\n\n\"云山已死，三年之约已了。你做得很好。\"\n\"但接下来……老夫要告诉你一件事。\"\n\"黑角域里，有一个人——韩枫。\"\n\"他是老夫的叛徒弟子，当年偷走了海心焰。\"\n\"你迟早会与他对上。在那之前……你需要更强。\"\n\n\"老夫尚有三件事可以指点你。你选一件。\"",
      "xuner": "你体内的古族血脉突然剧烈跳动。\n一道金色的虚影在你面前凝聚——那是一位古族长老的残念。\n\n\"后辈……你的血脉比我们预想的更强。\"\n\"前方的路很危险。黑角域的黑暗会侵蚀你的灵魂。\"\n\"让老夫帮你稳固根基。\"",
      "cailin": "你感受到蛇族血脉中传来一股远古的共鸣。\n一道蛇瞳虚影在你面前浮现——那是一位远古蛇帝的残念。\n\n\"美杜莎的后裔……你体内的血脉，比你想象的更古老。\"\n\"黑角域里有毒瘴弥漫之地，那里与我蛇族有渊源。\"\n\"去吧。但在此之前，让先祖赐你一份力量。\""
    },
    "character_choices": {
      "xiaoyan": [
        {
          "text": "药老指点·净心",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "药老指点·炼体",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 100,
              "ref": "",
              "desc": "获得100金币"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "药老指点·备药",
          "outcomes": [
            {
              "type": "POTION",
              "value": 2,
              "ref": "rare",
              "desc": "获得2瓶高级丹药"
            }
          ]
        }
      ],
      "xuner": [
        {
          "text": "古族洗礼·净脉",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "古族秘法·觉醒",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 100,
              "ref": "",
              "desc": "获得100金币"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "古族遗宝·灵药",
          "outcomes": [
            {
              "type": "POTION",
              "value": 2,
              "ref": "rare",
              "desc": "获得2瓶高级丹药"
            }
          ]
        }
      ],
      "cailin": [
        {
          "text": "蛇族淬体·蜕鳞",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "蛇族秘术·噬血",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 100,
              "ref": "",
              "desc": "获得100金币"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "蛇族遗蜕·蛇胆",
          "outcomes": [
            {
              "type": "POTION",
              "value": 2,
              "ref": "rare",
              "desc": "获得2瓶高级丹药"
            }
          ]
        }
      ]
    },
    "bg_images": {
      "xiaoyan": "assets/events/event_bg_ancient_scene2_xiaoyan.png",
      "xuner": "assets/events/event_bg_ancient_scene2_xuner.png",
      "cailin": "assets/events/event_bg_ancient_scene2_cailin.png"
    },
    "bg_image": "assets/events/event_bg_ancient_scene2_xiaoyan.png"
  },
  {
    "file": "event_blazing_tower.gd",
    "scene_dir": "canaan",
    "id": 21,
    "name": "天焚炼气塔修炼",
    "description": "天焚炼气塔散发出灼热的能量波动，修炼者们排队进入。你感受到了塔底那股远古力量的脉动。",
    "category": "PLOT",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "深层修炼",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 10,
            "ref": "",
            "desc": "高温灼伤，受到10点伤害"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 1,
            "ref": "",
            "desc": "永久+1力量"
          }
        ]
      },
      {
        "text": "浅层修炼",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 15,
            "ref": "",
            "desc": "回复15点生命值"
          },
          {
            "type": "GOLD",
            "value": 50,
            "ref": "",
            "desc": "获得50金币"
          }
        ]
      },
      {
        "text": "探查塔底",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "",
            "desc": "获得随机卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_blazing_tower_cultivation.png"
  },
  {
    "file": "event_ranking_challenge.gd",
    "scene_dir": "canaan",
    "id": 22,
    "name": "强榜挑战赛",
    "description": "内院强榜擂台上，强者云集。选择你想挑战的对手。",
    "category": "PLOT",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "挑战韩月",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "han_yue_challenge",
            "desc": "挑战韩月"
          },
          {
            "type": "GOLD",
            "value": 250,
            "ref": "",
            "desc": "获得250金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "21",
            "desc": "获得强榜玉牌"
          }
        ]
      },
      {
        "text": "挑战紫妍",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "ziyan_challenge",
            "desc": "挑战紫妍"
          },
          {
            "type": "GOLD",
            "value": 350,
            "ref": "",
            "desc": "获得350金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "观战学习",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 30,
            "ref": "",
            "desc": "获得30金币"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "learned_from_observation",
            "desc": "下场战斗额外抽1牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ranking_challenge.png"
  },
  {
    "file": "event_ancient_clan_treasure.gd",
    "scene_dir": "canaan",
    "id": 23,
    "name": "古族秘宝",
    "description": "深入古界，你感受到了神品血脉的共鸣。一道金色的光芒从地底涌出。",
    "category": "PLOT",
    "scene_id": 4,
    "character": "xuner",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "激活血脉",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "divine_blood",
            "desc": "获得传说卡牌神品血脉"
          },
          {
            "type": "MAX_HP",
            "value": -5,
            "ref": "",
            "desc": "最大生命值-5"
          }
        ]
      },
      {
        "text": "接受传承",
        "outcomes": [
          {
            "type": "UPGRADE_CARD",
            "value": 3,
            "ref": "",
            "desc": "升级3张卡牌"
          }
        ]
      },
      {
        "text": "触碰禁忌",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "38",
            "desc": "获得风雷阁主令"
          },
          {
            "type": "CURSE_CARD",
            "value": 1,
            "ref": "ancient_clan_forbidden",
            "desc": "获得诅咒牌古族禁令"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_clan_treasure.png"
  },
  {
    "file": "event_cultivation_deviation.gd",
    "scene_dir": "canaan",
    "id": 24,
    "name": "走火入魔的学员",
    "description": "天焚炼气塔底层，一个学员双眼通红，正在疯狂攻击周围的修炼者。",
    "category": "COMBAT",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "强行制服",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "cultivation_deviation_fight",
            "desc": "制服走火入魔者"
          },
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "",
            "desc": "获得随机卡牌"
          }
        ]
      },
      {
        "text": "用丹药救治",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "56",
            "desc": "获得山岳之心"
          }
        ]
      },
      {
        "text": "无视",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_cultivation_deviation.png"
  },
  {
    "file": "event_earth_devil_lair.gd",
    "scene_dir": "canaan",
    "id": 25,
    "name": "地魔老鬼巢穴",
    "description": "塔底深处，你发现了一处隐秘的洞穴，里面传出阴冷的灵魂波动。",
    "category": "COMBAT",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "突袭",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "earth_devil_fight",
            "desc": "突袭地魔老鬼"
          },
          {
            "type": "GOLD",
            "value": 300,
            "ref": "",
            "desc": "获得300金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "31",
            "desc": "获得远古魔核"
          }
        ]
      },
      {
        "text": "偷取秘籍",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "CURSE_CARD",
            "value": 1,
            "ref": "earth_devil_curse",
            "desc": "获得诅咒牌地魔诅咒"
          }
        ]
      },
      {
        "text": "封印洞穴",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 15,
            "ref": "",
            "desc": "受到15点伤害"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 1,
            "ref": "",
            "desc": "永久+1力量"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_earth_devil_lair.png"
  },
  {
    "file": "event_resource_battle.gd",
    "scene_dir": "canaan",
    "id": 26,
    "name": "修炼资源争夺",
    "description": "内院深处发现了一处远古修炼密室，里面蕴含着浓郁的天地能量。",
    "category": "COMBAT",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "强夺",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "resource_battle",
            "desc": "击败内院弟子"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得高级丹药"
          }
        ]
      },
      {
        "text": "协商分配",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          }
        ]
      },
      {
        "text": "放弃",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 30,
            "ref": "",
            "desc": "获得30金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_resource_battle.png"
  },
  {
    "file": "event_herb_garden.gd",
    "scene_dir": "canaan",
    "id": 27,
    "name": "药圃奇遇",
    "description": "迦南学院的药圃中，一株罕见的灵药正在绽放。药老的声音在你脑海中响起。",
    "category": "REWARD",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "采摘灵药",
        "outcomes": [
          {
            "type": "HEAL",
            "value": 40,
            "ref": "",
            "desc": "回复40%最大HP"
          }
        ]
      },
      {
        "text": "炼制丹药",
        "outcomes": [
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "获得2瓶丹药"
          }
        ]
      },
      {
        "text": "移植",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "54",
            "desc": "获得灵药圃"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_herb_garden.png"
  },
  {
    "file": "event_ancient_cave.gd",
    "scene_dir": "canaan",
    "id": 28,
    "name": "古修洞府",
    "description": "一处被遗忘的远古修炼洞府，里面的阵法仍在运转。",
    "category": "REWARD",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "修炼",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 1,
            "ref": "",
            "desc": "永久+1力量"
          }
        ]
      },
      {
        "text": "探索",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得随机遗物"
          },
          {
            "type": "GOLD",
            "value": 80,
            "ref": "",
            "desc": "获得80金币"
          }
        ]
      },
      {
        "text": "破阵取宝",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 20,
            "ref": "",
            "desc": "受到20点伤害"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_cave.png"
  },
  {
    "file": "event_fallen_heart_flame.gd",
    "scene_dir": "canaan",
    "id": 29,
    "name": "陨落心炎封印松动",
    "description": "封印出现裂痕，心炎的能量正在泄漏。你可以选择冒险汲取这股力量。",
    "category": "RISK",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "汲取心炎",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "CURSE_CARD",
            "value": 1,
            "ref": "heart_fire_burn",
            "desc": "获得诅咒牌心火灼烧"
          }
        ]
      },
      {
        "text": "加固封印",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 25,
            "ref": "",
            "desc": "受到25点伤害"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "37",
            "desc": "获得焚炎谷令"
          }
        ]
      },
      {
        "text": "释放心炎",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "fallen_heart_flame",
            "desc": "与陨落心炎交战"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "40",
            "desc": "获得守护者之证"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_fallen_heart_flame.png"
  },
  {
    "file": "event_inner_academy_forbidden.gd",
    "scene_dir": "canaan",
    "id": 30,
    "name": "内院禁地",
    "description": "内院禁地中封印着一柄远古神兵，守卫极其森严。",
    "category": "RISK",
    "scene_id": 3,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "强闯",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "forbidden_guard_fight",
            "desc": "击败禁地守卫"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说卡牌"
          }
        ]
      },
      {
        "text": "贿赂守卫",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得随机遗物"
          }
        ]
      },
      {
        "text": "放弃",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_inner_academy_forbidden.png"
  },
  {
    "file": "event_lava_world_entrance.gd",
    "scene_dir": "canaan",
    "id": 31,
    "name": "岩浆世界入口",
    "description": "天焚炼气塔底层的最深处，你发现了一个散发着灼热气息的洞穴入口。",
    "category": "RISK",
    "scene_id": 3,
    "character": "xiaoyan",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "硬抗高温深入",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 15,
            "ref": "",
            "desc": "受到15点伤害"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "",
            "desc": "获得随机卡牌"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "ancient_emperor",
            "desc": "触发古帝之谜事件链"
          }
        ]
      },
      {
        "text": "用丹药护体",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "抽身离去",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_lava_world_entrance.png"
  },
  {
    "file": "event_ancient_scene3.gd",
    "scene_dir": "ancient",
    "id": 101,
    "name": "守灵",
    "description": "",
    "category": "SPECIAL",
    "scene_id": 3,
    "character": "",
    "is_ancient": true,
    "is_forced": false,
    "choices": [],
    "character_options": {
      "xiaoyan": [
        "药老传授·秘技",
        "药老传授·洗髓",
        "药老传授·古法"
      ],
      "xuner": [
        "古族传承·武学",
        "古族传承·洗髓",
        "古族传承·遗宝"
      ],
      "cailin": [
        "蛇族传承·蛇瞳",
        "蛇族传承·蜕皮",
        "蛇族传承·蛇骨"
      ]
    },
    "character_dialogs": {
      "xiaoyan": "迦南学院的地底深处，药尘的虚影再次浮现。\n\n\"陨落心炎……排名第十四的异火。\"\n\"当年老夫也曾觊觎它，但最终选择了放弃。\"\n\"如今它就在你面前。老夫有三件事要交代。\"\n\"选一件，然后去面对你的命运。\"",
      "xuner": "古族的血脉在迦南学院的远古遗迹中产生了强烈共鸣。\n一道更加清晰的古族长老虚影出现。\n\n\"这里的远古遗迹……与我古族有千丝万缕的关联。\"\n\"你的血脉在这里得到了进一步的淬炼。\"\n\"让老夫再助你一臂之力。\"",
      "cailin": "迦南学院地底的岩浆世界入口处，蛇族先祖的虚影变得更加凝实。\n\n\"这里的火焰……与我蛇族的远古记忆有关。\"\n\"美杜莎的后裔，你的双生姿态即将迎来蜕变。\"\n\"接受先祖最后的传承吧。\""
    },
    "character_choices": {
      "xiaoyan": [
        {
          "text": "药老传授·秘技",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 80,
              "ref": "",
              "desc": "获得80金币"
            }
          ]
        },
        {
          "text": "药老传授·洗髓",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "药老传授·古法",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -8,
              "ref": "",
              "desc": "最大生命值-8"
            }
          ]
        }
      ],
      "xuner": [
        {
          "text": "古族传承·武学",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 80,
              "ref": "",
              "desc": "获得80金币"
            }
          ]
        },
        {
          "text": "古族传承·洗髓",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "古族传承·遗宝",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -8,
              "ref": "",
              "desc": "最大生命值-8"
            }
          ]
        }
      ],
      "cailin": [
        {
          "text": "蛇族传承·蛇瞳",
          "outcomes": [
            {
              "type": "CARD",
              "value": 1,
              "ref": "rare",
              "desc": "获得1张稀有卡牌"
            },
            {
              "type": "GOLD",
              "value": 80,
              "ref": "",
              "desc": "获得80金币"
            }
          ]
        },
        {
          "text": "蛇族传承·蜕皮",
          "outcomes": [
            {
              "type": "REMOVE_CARD",
              "value": 2,
              "ref": "basic",
              "desc": "移除2张基础牌"
            },
            {
              "type": "CARD",
              "value": 2,
              "ref": "advanced",
              "desc": "替换为2张进阶卡牌"
            }
          ]
        },
        {
          "text": "蛇族传承·蛇骨",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -8,
              "ref": "",
              "desc": "最大生命值-8"
            }
          ]
        }
      ]
    },
    "bg_images": {
      "xiaoyan": "assets/events/event_bg_ancient_scene3_xiaoyan.png",
      "xuner": "assets/events/event_bg_ancient_scene3_xuner.png",
      "cailin": "assets/events/event_bg_ancient_scene3_cailin.png"
    },
    "bg_image": "assets/events/event_bg_ancient_scene3_xiaoyan.png"
  },
  {
    "file": "event_pill_tower_trial.gd",
    "scene_dir": "central",
    "id": 32,
    "name": "丹塔历练",
    "description": "丹塔七层，每层都有不同等级的考验。塔顶的老者注视着你。",
    "category": "PLOT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "挑战第五层",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "pill_tower_guard_fight",
            "desc": "击败丹塔守卫"
          },
          {
            "type": "GOLD",
            "value": 300,
            "ref": "",
            "desc": "获得300金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "57",
            "desc": "获得丹塔秘卷"
          }
        ]
      },
      {
        "text": "挑战第三层",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 150,
            "ref": "",
            "desc": "获得150金币"
          },
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "获得2瓶丹药"
          }
        ]
      },
      {
        "text": "在第一层研习",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "UPGRADE_CARD",
            "value": 1,
            "ref": "",
            "desc": "升级1张卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_pill_tower_trial.png"
  },
  {
    "file": "event_soul_hall_outpost.gd",
    "scene_dir": "central",
    "id": 33,
    "name": "魂殿据点",
    "description": "你误入了一处魂殿的灵魂收割据点，阴冷的锁链声在黑暗中回荡。",
    "category": "PLOT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "突袭祭坛",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "soul_hall_ambush_fight",
            "desc": "击败魂殿尊老"
          },
          {
            "type": "GOLD",
            "value": 400,
            "ref": "",
            "desc": "获得400金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得随机遗物"
          }
        ]
      },
      {
        "text": "窃取灵魂碎片",
        "outcomes": [
          {
            "type": "UPGRADE_CARD",
            "value": 2,
            "ref": "",
            "desc": "升级2张卡牌"
          },
          {
            "type": "CURSE_CARD",
            "value": 1,
            "ref": "soul_trauma",
            "desc": "获得诅咒牌灵魂创伤"
          }
        ]
      },
      {
        "text": "屏息潜行",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 3,
            "ref": "",
            "desc": "受到3点伤害"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_soul_hall_outpost.png"
  },
  {
    "file": "event_ancient_gate.gd",
    "scene_dir": "central",
    "id": 34,
    "name": "古界之门",
    "description": "一道金色的巨门矗立在你面前，门上刻着古族的族徽。你的血脉在沸腾。",
    "category": "PLOT",
    "scene_id": 4,
    "character": "xuner",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "进入古界",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "28",
            "desc": "获得古族玉佩"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "ancient_clan_heritage",
            "desc": "解锁古族传承"
          }
        ]
      },
      {
        "text": "隔门感应",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 2,
            "ref": "",
            "desc": "永久+2力量"
          }
        ]
      },
      {
        "text": "封印古门",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 20,
            "ref": "",
            "desc": "受到20点伤害"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_gate.png"
  },
  {
    "file": "event_alliance.gd",
    "scene_dir": "central",
    "id": 35,
    "name": "天府联盟成立",
    "description": "各方势力齐聚，商讨对抗魂殿的大计。众人推举你为联盟盟主。",
    "category": "PLOT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "担任盟主",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "42",
            "desc": "获得大长老手令"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "alliance_formed",
            "desc": "联盟集结"
          }
        ]
      },
      {
        "text": "推举他人",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "POTION",
            "value": 1,
            "ref": "",
            "desc": "获得高级丹药"
          }
        ]
      },
      {
        "text": "独行",
        "outcomes": [
          {
            "type": "CARD",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_alliance_formed.png"
  },
  {
    "file": "event_soul_elders_ambush.gd",
    "scene_dir": "central",
    "id": 36,
    "name": "魂殿尊老伏击",
    "description": "四位魂殿尊老挡住了你的去路。他们的灵魂力量扭曲了周围的空间。",
    "category": "COMBAT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "正面迎战",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "soul_elders_group_fight",
            "desc": "击败四大尊老"
          },
          {
            "type": "GOLD",
            "value": 400,
            "ref": "",
            "desc": "获得400金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得随机遗物"
          }
        ]
      },
      {
        "text": "各个击破",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "soul_hall_elder",
            "desc": "击败魂殿长老"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "灵魂隐匿",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 15,
            "ref": "",
            "desc": "受到15点伤害"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_soul_hall_ambush.png"
  },
  {
    "file": "event_ancient_puppet.gd",
    "scene_dir": "central",
    "id": 37,
    "name": "远古傀儡守卫",
    "description": "古帝洞府入口，一尊远古傀儡矗立在通道中央。万年过去，它仍在执行守护指令。",
    "category": "COMBAT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "强攻",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "ancient_puppet_fight",
            "desc": "击败远古傀儡"
          },
          {
            "type": "GOLD",
            "value": 250,
            "ref": "",
            "desc": "获得250金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "35",
            "desc": "获得天妖傀"
          }
        ]
      },
      {
        "text": "寻找弱点",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 10,
            "ref": "",
            "desc": "受到10点伤害"
          },
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "ancient_puppet_fight",
            "desc": "击败削弱的傀儡"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          }
        ]
      },
      {
        "text": "绕道",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 8,
            "ref": "",
            "desc": "受到8点伤害"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_puppet.png"
  },
  {
    "file": "event_ancient_trial.gd",
    "scene_dir": "central",
    "id": 38,
    "name": "古族试炼",
    "description": "古帝洞府中，一道远古意志降临——古族战士的虚影出现在你面前。",
    "category": "COMBAT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "接受试炼",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "ancient_clan_trial_fight",
            "desc": "通过古族试炼"
          },
          {
            "type": "GOLD",
            "value": 300,
            "ref": "",
            "desc": "获得300金币"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 2,
            "ref": "",
            "desc": "永久+2力量"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "rare",
            "desc": "获得稀有卡牌"
          }
        ]
      },
      {
        "text": "献祭精血",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 25,
            "ref": "",
            "desc": "受到25点伤害"
          },
          {
            "type": "GOLD",
            "value": 200,
            "ref": "",
            "desc": "获得200金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "random_common",
            "desc": "获得随机遗物"
          }
        ]
      },
      {
        "text": "放弃",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_clan_trial.png"
  },
  {
    "file": "event_soul_storm.gd",
    "scene_dir": "central",
    "id": 39,
    "name": "灵魂风暴",
    "description": "一场灵魂风暴席卷了整个区域，无数灵魂虚影在风暴中嘶吼。",
    "category": "COMBAT",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "穿越风暴",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "soul_storm_fight",
            "desc": "穿越灵魂风暴"
          },
          {
            "type": "GOLD",
            "value": 350,
            "ref": "",
            "desc": "获得350金币"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "34",
            "desc": "获得星陨护心令"
          }
        ]
      },
      {
        "text": "等待风暴过去",
        "outcomes": [
          {
            "type": "DAMAGE",
            "value": 10,
            "ref": "",
            "desc": "受到10点伤害"
          },
          {
            "type": "GOLD",
            "value": 50,
            "ref": "",
            "desc": "获得50金币"
          }
        ]
      },
      {
        "text": "汲取灵魂能量",
        "outcomes": [
          {
            "type": "MAX_HP",
            "value": -30,
            "ref": "",
            "desc": "最大HP-30"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说卡牌"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_soul_storm.png"
  },
  {
    "file": "event_medicine_clan.gd",
    "scene_dir": "central",
    "id": 40,
    "name": "药族秘境",
    "description": "药族秘境的大门向你敞开，里面保存着远古炼药师的传承。",
    "category": "REWARD",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "接受传承",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "41",
            "desc": "获得药族秘传"
          }
        ]
      },
      {
        "text": "搜刮药库",
        "outcomes": [
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "获得2瓶丹药"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      },
      {
        "text": "研习药方",
        "outcomes": [
          {
            "type": "UPGRADE_CARD",
            "value": 2,
            "ref": "",
            "desc": "升级2张卡牌"
          },
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_medicine_clan.png"
  },
  {
    "file": "event_pill_tower_secret.gd",
    "scene_dir": "central",
    "id": 41,
    "name": "丹塔密室",
    "description": "丹塔最深处的密室中，一尊远古药鼎散发着微弱的光芒。鼎内的药液仍在沸腾。",
    "category": "REWARD",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "取丹",
        "outcomes": [
          {
            "type": "POTION",
            "value": 2,
            "ref": "",
            "desc": "获得2瓶高级丹药"
          }
        ]
      },
      {
        "text": "探索密室",
        "outcomes": [
          {
            "type": "RELIC",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说遗物"
          },
          {
            "type": "DAMAGE",
            "value": 30,
            "ref": "",
            "desc": "受到30点伤害"
          }
        ]
      },
      {
        "text": "离开",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_pill_tower_secret.png"
  },
  {
    "file": "event_ancient_emperor_soul.gd",
    "scene_dir": "central",
    "id": 42,
    "name": "古帝残魂",
    "description": "一道远古的残魂出现在你面前，它是斗帝留下的最后一丝意志。",
    "category": "RISK",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": true,
    "choices": [
      {
        "text": "接受考验",
        "outcomes": [
          {
            "type": "COMBAT",
            "value": 0,
            "ref": "ancient_emperor_soul",
            "desc": "与古帝残魂交战"
          },
          {
            "type": "RELIC",
            "value": 0,
            "ref": "58",
            "desc": "获得古帝残魂碎片"
          }
        ]
      },
      {
        "text": "汲取残魂",
        "outcomes": [
          {
            "type": "MAX_HP",
            "value": -30,
            "ref": "",
            "desc": "最大HP-30"
          },
          {
            "type": "CARD",
            "value": 0,
            "ref": "legendary",
            "desc": "获得传说卡牌"
          },
          {
            "type": "PERMA_STRENGTH",
            "value": 3,
            "ref": "",
            "desc": "永久+3力量"
          }
        ]
      },
      {
        "text": "敬而远之",
        "outcomes": [
          {
            "type": "GOLD",
            "value": 100,
            "ref": "",
            "desc": "获得100金币"
          }
        ]
      }
    ],
    "bg_image": "assets/events/event_bg_ancient_emperor_soul.png"
  },
  {
    "file": "event_huntiandi_plot.gd",
    "scene_dir": "central",
    "id": 43,
    "name": "魂天帝的阴谋",
    "description": "魂天帝的声音在虚空中回荡——你以为你能阻止我？",
    "category": "RISK",
    "scene_id": 4,
    "character": "",
    "is_ancient": false,
    "is_forced": false,
    "choices": [
      {
        "text": "以命换命",
        "outcomes": [
          {
            "type": "MAX_HP",
            "value": -15,
            "ref": "",
            "desc": "最大HP-15"
          },
          {
            "type": "FLAG",
            "value": 0,
            "ref": "huntiandi_hp_reduced",
            "desc": "魂天帝HP-100"
          }
        ]
      },
      {
        "text": "以魂铸甲",
        "outcomes": [
          {
            "type": "FLAG",
            "value": 0,
            "ref": "huntiandi_strength_reduced",
            "desc": "魂天帝力量-2"
          }
        ]
      },
      {
        "text": "正面决战",
        "outcomes": []
      }
    ],
    "bg_image": "assets/events/event_bg_huntiandi_plot.png"
  },
  {
    "file": "event_ancient_scene4.gd",
    "scene_dir": "ancient",
    "id": 102,
    "name": "守灵",
    "description": "",
    "category": "SPECIAL",
    "scene_id": 4,
    "character": "",
    "is_ancient": true,
    "is_forced": false,
    "choices": [],
    "character_options": {
      "xiaoyan": [
        "药老最后的教诲·顿悟",
        "药老最后的教诲·传承",
        "药老最后的教诲·印记"
      ],
      "xuner": [
        "古族长老·血脉觉醒",
        "古族长老·古帝遗宝",
        "古族长老·帝境感悟"
      ],
      "cailin": [
        "蛇族先祖·终极蜕变",
        "蛇族先祖·远古蛇蜕",
        "蛇族先祖·蛇帝之力"
      ]
    },
    "character_dialogs": {
      "xiaoyan": "中州的天空中，药尘的虚影变得前所未有的清晰。\n\n\"孩子……老夫的时间不多了。\"\n\"魂天帝已经察觉到了你的存在。\"\n\"古帝洞府的钥匙……就在你身上。\"\n\"这是老夫最后能给你的东西。选一件吧。\"",
      "xuner": "古界之门在你面前缓缓打开。\n古族长老的虚影最后一次出现，眼中满是欣慰。\n\n\"后辈……你已经走到了这里。\"\n\"古帝的遗产，等待着有资格的人。\"\n\"让老夫为你开启最后的传承。\"",
      "cailin": "中州的虚空中，蛇族先祖的虚影散发着古老而威严的气息。\n\n\"美杜莎的后裔……你已经证明了自己的资格。\"\n\"九彩吞天蟒的血脉，在你身上达到了前所未有的高度。\"\n\"接受先祖最后的馈赠吧。\""
    },
    "character_choices": {
      "xiaoyan": [
        {
          "text": "药老最后的教诲·顿悟",
          "outcomes": [
            {
              "type": "UPGRADE_CARD",
              "value": 2,
              "ref": "",
              "desc": "随机升级2张卡牌"
            }
          ]
        },
        {
          "text": "药老最后的教诲·传承",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "药老最后的教诲·印记",
          "outcomes": [
            {
              "type": "PERMA_STRENGTH",
              "value": 1,
              "ref": "",
              "desc": "永久力量+1"
            }
          ]
        }
      ],
      "xuner": [
        {
          "text": "古族长老·血脉觉醒",
          "outcomes": [
            {
              "type": "UPGRADE_CARD",
              "value": 2,
              "ref": "",
              "desc": "随机升级2张卡牌"
            }
          ]
        },
        {
          "text": "古族长老·古帝遗宝",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "古族长老·帝境感悟",
          "outcomes": [
            {
              "type": "PERMA_STRENGTH",
              "value": 1,
              "ref": "",
              "desc": "永久力量+1"
            }
          ]
        }
      ],
      "cailin": [
        {
          "text": "蛇族先祖·终极蜕变",
          "outcomes": [
            {
              "type": "UPGRADE_CARD",
              "value": 2,
              "ref": "",
              "desc": "随机升级2张卡牌"
            }
          ]
        },
        {
          "text": "蛇族先祖·远古蛇蜕",
          "outcomes": [
            {
              "type": "RELIC",
              "value": 0,
              "ref": "rare",
              "desc": "获得稀有遗物"
            },
            {
              "type": "MAX_HP",
              "value": -10,
              "ref": "",
              "desc": "失去10%最大HP"
            }
          ]
        },
        {
          "text": "蛇族先祖·蛇帝之力",
          "outcomes": [
            {
              "type": "PERMA_STRENGTH",
              "value": 1,
              "ref": "",
              "desc": "永久力量+1"
            }
          ]
        }
      ]
    },
    "bg_images": {
      "xiaoyan": "assets/events/event_bg_ancient_scene4_xiaoyan.png",
      "xuner": "assets/events/event_bg_ancient_scene4_xuner.png",
      "cailin": "assets/events/event_bg_ancient_scene4_cailin.png"
    },
    "bg_image": "assets/events/event_bg_ancient_scene4_xiaoyan.png"
  }
];
const SCENE_MAP = {
  "0": {
    "name": "特殊",
    "en": "Special",
    "color": "#888888"
  },
  "1": {
    "name": "加玛帝国",
    "en": "Jia Ma Empire",
    "color": "#4a7c59"
  },
  "2": {
    "name": "黑角域",
    "en": "Black Corner",
    "color": "#7a6e5d"
  },
  "3": {
    "name": "迦南学院",
    "en": "Canaan Academy",
    "color": "#3a6b8c"
  },
  "4": {
    "name": "中州",
    "en": "Central Plains",
    "color": "#c23a2b"
  }
};
const CATEGORY_MAP = {
  "PLOT": {
    "name": "剧情",
    "color": "#3a6b8c"
  },
  "COMBAT": {
    "name": "战斗",
    "color": "#c23a2b"
  },
  "REWARD": {
    "name": "奖励",
    "color": "#b8963e"
  },
  "RISK": {
    "name": "风险",
    "color": "#d4763c"
  },
  "SPECIAL": {
    "name": "特殊",
    "color": "#8b5cf6"
  }
};
