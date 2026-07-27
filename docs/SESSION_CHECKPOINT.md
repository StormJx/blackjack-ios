# 会话检查点（可推送 GitHub）

> 本地另有 `VERSION_ROADMAP.txt`（gitignore，勿推送）。两边请同步维护。  
> 成就：`docs/ACHIEVEMENTS.md` · 外观道具：`docs/COSMETICS_AND_PROPS.md` · P8 后续：`docs/P8_ORIENTATION_AND_A11Y.md`

**基线：** 本批增量在 `main` @ `9715bf5` 之上（Tag `v1.10.0` 为上一里程碑；推送后请改写 commit）  
**仓库：** https://github.com/StormJx/blackjack-ios  
**平台：** iOS 17.0+；庄家小于 17 要牌、大于等于 17 停（软 17 同停）；音效基名 deal/flip/shuffle/win/lose/push

---

## 模式分工

| 模式 | 筹码 | 玩法道具 | 切牌 | 其它 |
|------|------|----------|------|------|
| 闯关 `.challenge` | 关卡进阶 | **禁用** | **设置三态**（每局重洗 / 仪式感 / 真实） | 成就 challenge 轨 |
| 娱乐 `.entertainment`（rawValue=`fast`） | **独立阶梯** + 注码随阶 | **可用** | **固定真实切牌** | 「同上局」；成就 practice 轨 |

成就分轨：娱乐不计入闯关成就。外观（卡背）跨模式可选用。

---

## 已完成（v1.10 + 本批增量）

### 外观 / 设置 / 欢迎页
- [x] C1 卡背解锁 + 设置页选用（classicNavy / emeraldLattice / crimsonRibbon）
- [x] P4 桌限预设（标准/轻量/偏大）— **仅闯关新会话生效**；娱乐跟阶梯注码
- [x] P8 **深色**基础适配（对局 `TableBackgroundView` 跟随系统）
- [x] 欢迎页精简：牌桌绿底 + 游戏名 + 闯关/娱乐入口 + 帮助说明；顶栏成就/战绩/设置保留
- [x] `HelpView`：规则与模式说明迁入帮助；主页不再堆进度/道具/牌副文案
- [x] 开局牌副改读设置「默认牌副」（欢迎页无 Picker）
- [x] P5 切牌三态：`CutCardMode`（off / ceremonial / real）；设置 Picker；娱乐固定 real；旧布尔键可迁移
- [x] F1 全下解锁局数可配置（设置 Stepper 0–10，默认 5；`ActivePreDealAllInUnlock` 新会话生效；两模式共用）
- [~] F2 闯关进度弱提示：曾在欢迎页；现改为帮助/战绩侧说明（欢迎页已去掉冗余）

### 娱乐
- [x] 娱乐独立进阶 `EntertainmentProgress`（打穿或累计赢升阶；注码随阶）
- [x] P3 「同上局」下注（仅娱乐）
- [x] 娱乐固定真实切牌（设置切牌只影响闯关）
- [x] 道具：`midHandAllIn` / `dealerSoft17Hit` / `peekHole` / `redrawOne` / `reshuffleDealerCard`（仅娱乐，永久解锁）
- [x] `reshuffleDealerCard`：解锁 `practiceWins50`；每局限 1；随机含暗牌；窥视中禁用；牌面脉冲 +「已换庄家一张」弱提示；音效 `shuffleHint`
- [x] F10：六基名 wav 升为 44.1kHz 高质量程序合成（仍非录音正片；可替换 `Sounds/`）

### 规划入库（效果未接线）
- [x] P8 横竖屏 / 无障碍深化 → 仅文档备案

---

## 未完成（须点名再做）

| 编号 | 内容 | 备注 |
|------|------|------|
| P8 横竖屏 | 允许横屏与布局 | 见 P8 文档 |
| P8 无障碍深化 | VoiceOver / 动态字体等 | 见 P8 文档 |
| F10 正片录音 | 录音级素材替换 | 基名不变，替换 Sounds/ 即可 |
| C5 | 对道具战模式 | 须先锁产品 |
| P6 | 分牌/加倍/保险/投降 | 大改，须锁规则 |
| 娱乐阶梯数值 | 试玩后再调 | 当前表保持 |

**明确不做：** 闯关启用玩法道具；娱乐计入闯关成就；默认模式内独立「练习分」。

---

## 工程要点

- `PlayStyle` / `PropStore` / `ChallengeProgress` / `EntertainmentProgress` / `CosmeticsStore` / `TableLimitPreset` / `CutCardMode` / `ActivePreDealAllInUnlock` / `HelpView`
- `ChipBank` 支持会话起始筹码；退出清空持久化键
- `BlackjackGame` 只发牌；筹码 `ChipBank`；成就 `StatsStore`
- 推送前：`./scripts/check-before-push.sh`；勿提交 `VERSION_ROADMAP.txt` / `.env` / 密钥

---

## 建议下一步（任选点名）

1. 试玩后调娱乐阶梯数值  
2. 提供录音级 wav 换 F10 正片  
3. P8 横竖或无障碍切片  
4. 讨论 C5 / P6 产品  

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-23 | 初版检查点：对应 v1.10 推送交接 |
| 2026-07-23 | `reshuffleDealerCard` 接线（`practiceWins50`；仅娱乐） |
| 2026-07-23 | 换庄家体验：正向单测、牌面脉冲弱提示、窥视中禁用、道具两列网格 |
| 2026-07-23 | 欢迎页精简：牌桌绿 + 双入口 + HelpView；牌副改走设置默认；基线 `6ebe464` |
| 2026-07-25 | P5 切牌三态 + F1 全下解锁可配置 + F10 44.1kHz 合成音增强 |
