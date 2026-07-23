# 会话检查点（可推送 GitHub）

> 本地另有 `VERSION_ROADMAP.txt`（gitignore，勿推送）。两边请同步维护。  
> 成就：`docs/ACHIEVEMENTS.md` · 外观道具：`docs/COSMETICS_AND_PROPS.md` · P8 后续：`docs/P8_ORIENTATION_AND_A11Y.md`

**基线：** `main` @ Tag `v1.10.0`（若尚未打 Tag，以最新 push commit 为准）  
**仓库：** https://github.com/StormJx/blackjack-ios  
**平台：** iOS 17.0+；庄家小于 17 要牌、大于等于 17 停（软 17 同停）；音效基名 deal/flip/shuffle/win/lose/push

---

## 模式分工

| 模式 | 筹码 | 玩法道具 | 切牌 | 其它 |
|------|------|----------|------|------|
| 闯关 `.challenge` | 关卡进阶 | **禁用** | 跟设置开关 | 成就 challenge 轨 |
| 娱乐 `.entertainment`（rawValue=`fast`） | **独立阶梯** + 注码随阶 | **可用** | **固定真实切牌** | 「同上局」；成就 practice 轨 |

成就分轨：娱乐不计入闯关成就。外观（卡背）跨模式可选用。

---

## 已完成（v1.10 本批 + 既有 v1.9）

### 外观 / 设置
- [x] C1 卡背解锁 + 设置页选用（classicNavy / emeraldLattice / crimsonRibbon）
- [x] P4 桌限预设（标准/轻量/偏大）— **仅闯关新会话生效**；娱乐跟阶梯注码
- [x] P8 **深色**基础适配（`TableBackgroundView` 跟随系统）
- [x] F2 闯关欢迎页进度弱提示

### 娱乐
- [x] 娱乐独立进阶 `EntertainmentProgress`（打穿或累计赢升阶；注码随阶）
- [x] P3 「同上局」下注（仅娱乐）
- [x] 娱乐固定真实切牌（设置切牌开关只影响闯关）
- [x] 道具：`midHandAllIn` / `dealerSoft17Hit` / `peekHole` / `redrawOne`（仅娱乐，永久解锁）
- [x] F10：六基名 wav 已换为程序合成增强版（非录音级）

### 规划入库（效果未接线）
- [x] `PlannedPropID.reshuffleDealerCard` + `Deck.returnCardToShoe`（解锁条件未定）
- [x] P8 横竖屏 / 无障碍深化 → 仅文档备案

---

## 未完成（须点名再做）

| 编号 | 内容 | 备注 |
|------|------|------|
| reshuffleDealerCard | 接线 UI/规则 | 解锁条件用户未定 |
| P5 | 切牌「仅仪式感」三态 | 娱乐已固定真实切牌；仪式感另议 |
| P8 横竖屏 | 允许横屏与布局 | 见 P8 文档 |
| P8 无障碍深化 | VoiceOver / 动态字体等 | 见 P8 文档 |
| F10 正片 | 录音级素材替换 | 基名不变，替换 Sounds/ 即可 |
| F1 | 全下解锁局数可配置 | |
| C5 | 对道具战模式 | 须先锁产品 |
| P6 | 分牌/加倍/保险/投降 | 大改，须锁规则 |
| 娱乐阶梯数值 | 试玩后再调 | 当前表保持 |

**明确不做：** 闯关启用玩法道具；娱乐计入闯关成就；默认模式内独立「练习分」。

---

## 工程要点

- `PlayStyle` / `PropStore` / `ChallengeProgress` / `EntertainmentProgress` / `CosmeticsStore` / `TableLimitPreset`
- `ChipBank` 支持会话起始筹码；退出清空持久化键
- `BlackjackGame` 只发牌；筹码 `ChipBank`；成就 `StatsStore`
- 推送前：`./scripts/check-before-push.sh`；勿提交 `VERSION_ROADMAP.txt` / `.env` / 密钥

---

## 建议下一步（任选点名）

1. 试玩后调娱乐阶梯数值  
2. 定 `reshuffleDealerCard` 解锁条件并接线  
3. 提供正片 wav 换 F10  
4. P8 横竖或无障碍切片  
5. 讨论 C5 / P6 产品  

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-23 | 初版检查点：对应 v1.10 推送交接 |
