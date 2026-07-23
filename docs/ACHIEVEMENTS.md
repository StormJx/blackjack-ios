# 成就目录（维护手册）

> 实现源码：`cards/Achievement.swift`  
> 持久化：`cards/StatsStore.swift`（闯关 / 娱乐分轨）  
> UI：`cards/AchievementsView.swift`（「闯关」「娱乐」页签）  
> 道具与卡背：`docs/COSMETICS_AND_PROPS.md`  
> **修改成就时请同步更新本文件与 `AchievementID`。**

## 设计原则

1. **模式隔离**：娱乐模式（`PlayStyle.entertainment` → `AchievementScope.practice`）的对局**不会**解锁闯关成就；闯关同理不会解锁娱乐成就。
2. **展示**：欢迎页「成就」入口 → 分栏查看已解锁 / 未解锁与进度条。
3. **道具兑换**：闯关成就 `dealerClear1` → 永久解锁 `midHandAllIn`；**仅娱乐模式可用**（闯关禁用玩法道具）。详见 `docs/COSMETICS_AND_PROPS.md`。

---

## 道具

| PropID | 标题 | 解锁条件 | 可用模式 |
|--------|------|----------|----------|
| `midHandAllIn` | 见牌后再全下 | 成就 `dealerClear1` | **仅娱乐** |
| `dealerSoft17Hit` | 庄家软 17 要牌 | 成就 `dealerClear5` | **仅娱乐** |
| `peekHole` | 窥视暗牌 | 成就 `practiceWinStreak5` | **仅娱乐** |
| `redrawOne` | 换一张 | 成就 `practiceWins20` | **仅娱乐** |
| `reshuffleDealerCard` | 换庄家一张 | 成就 `practiceWins50` | **仅娱乐** |

> `reshuffleDealerCard`：窥视进行中不可用；牌桌有「已换庄家一张」弱提示与牌面脉冲。

详见 `docs/COSMETICS_AND_PROPS.md`。

---

## 闯关模式（`AchievementScope.challenge`）

### 技巧 · 一次性

| ID | 标题 | 条件 |
|----|------|------|
| `fiveCardCharlie` | 五龙不过 | 单局 ≥5 张且未爆 |
| `speedBlackjack` | 极速黑杰克 | 开局两张天然 BJ |
| `comeback` | 绝地反击 | 最终点数 ≥20 且获胜 |
| `exactTwentyOne` | 压线求生 | 最终正好 21（非天然 BJ） |
| `braveHitOver17` | 险中求胜·十八 | 点数 >17 要牌未爆并获胜 |
| `braveHitOver18` | 险中求胜·十九 | 点数 >18 要牌未爆并获胜 |
| `braveHitOver19` | 险中求胜·二十 | 20 点要牌未爆并获胜 |
| `braveHit20To21` | 神之一手 | 20 点要牌正好 21 并获胜 |
| `firstHandWin` | 初手制胜 | 仅两张牌（非 BJ）获胜 |

### 连胜阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `winStreak3` | 连胜起步 | 最长连胜 ≥3 |
| `winStreak5` | 连胜节奏 | ≥5 |
| `winStreak10` | 连胜风暴 | ≥10 |

### 稳健（连续未爆）阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `noBust5` | 稳健玩家 | 最长连续未爆 ≥5 |
| `noBust10` | 稳如磐石 | ≥10 |
| `noBust20` | 钢铁神经 | ≥20 |

### 累计胜场阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `wins10` | 小有斩获 | 累计胜 10 |
| `wins25` | 牌桌熟手 | 25 |
| `wins50` | 常胜将军 | 50 |
| `wins100` | 百战荣光 | 100 |

### 平局阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `push10` | 平局入门 | 累计平局 10 |
| `push20` | 平局达人 | 20 |
| `push50` | 平局大师 | 50 |

### 庄家爆牌致胜阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `dealerBust10` | 爆牌收割·十 | 10 |
| `dealerBust25` | 爆牌收割·廿五 | 25 |
| `dealerBust50` | 爆牌收割·五十 | 50 |

### 天然黑杰克阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `naturalBJ5` | 黑杰克收藏·五 | 5 |
| `naturalBJ15` | 黑杰克收藏·十五 | 15 |
| `naturalBJ30` | 黑杰克收藏·三十 | 30 |

### 筹码 / 通关（仅闯关经济）

| ID | 标题 | 目标 |
|----|------|------|
| `chipsWon1000` | 小赚一笔 | 累计赢筹码 ≥1000 |
| `chipsWon5000` | 盆满钵满 | ≥5000 |
| `chipsWon20000` | 筹码大亨 | ≥20000 |
| `dealerClear1` | 打穿庄家 | 打穿庄家池 1 次 |
| `dealerClear5` | 庄家克星 | 5 次 |

### 全下获胜阶梯

| ID | 标题 | 目标 |
|----|------|------|
| `allInWin5` | 全下首胜 | 全下获胜累计 5 |
| `allInWin15` | 全下连捷 | 15 |
| `allInWin30` | 全下传说 | 30 |

> 「全下」判定：开局下注等于当时全部余额，或对局中追加至全部余额后获胜。

---

## 娱乐模式（`AchievementScope.practice`）

| ID | 标题 | 条件 |
|----|------|------|
| `practiceWinStreak5` | 练习连胜·五 | 最长连胜 ≥5 |
| `practiceWinStreak10` | 练习连胜·十 | ≥10 |
| `practiceWins20` | 练习胜场·二十 | 累计胜 20 |
| `practiceWins50` | 练习胜场·五十 | 50 |
| `practiceWins100` | 练习胜场·一百 | 100 |
| `practicePush10` | 练习平局·十 | 累计平局 10 |
| `practicePush20` | 练习平局·二十 | 20 |
| `practicePush50` | 练习平局·五十 | 50 |
| `practiceNoBust10` | 练习稳健·十 | 最长连续未爆 ≥10 |
| `practiceNoBust20` | 练习稳健·二十 | ≥20 |
| `practiceFiveCard` | 练习五龙 | 单局 5 张未爆 |
| `practiceNaturalBJ` | 练习极速 BJ | 开局天然 BJ |

---

## 计数说明

| 数量 | 范围 |
|------|------|
| 闯关 | 36 项 |
| 娱乐 | 12 项 |
| **合计** | **48**（以 `AchievementID.allCases.count` 为准） |

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-20 | 初版：E3 原 8 项 + 险中求胜 |
| 2026-07-20 | 分轨挑战/练习；扩建连胜/平局/胜场/稳健/BJ/筹码阶梯；独立成就页 |
| 2026-07-20 | 下注三档单选；挑战全下需本会话 5 局解锁；全下获胜阶梯 5/15/30 |
| 2026-07-22 | v1.9：成就 `dealerClear1` → 永久道具「见牌后再全下」 |
| 2026-07-22 | 道具仅娱乐可用；练习→娱乐；闯关进阶；见 COSMETICS_AND_PROPS.md |
| 2026-07-23 | C2/C3/C4：`peekHole` / `dealerSoft17Hit` / `redrawOne` 兑换与娱乐接线 |
| 2026-07-23 | `reshuffleDealerCard`：成就 `practiceWins50` → 永久解锁；仅娱乐接线 |
