# 会话检查点（可推送 GitHub）

> 本地另有 `VERSION_ROADMAP.txt`（gitignore，勿推送）。两边请同步维护。  
> 成就：`docs/ACHIEVEMENTS.md` · 外观道具：`docs/COSMETICS_AND_PROPS.md`  
> P8：`docs/P8_ORIENTATION_AND_A11Y.md` · 评审批次 backlog：`docs/ENGINEERING_REVIEW_BACKLOG.md`

**基线：** `main` @ `c5aa3ec`（「完成 P6+ 投降…」；含此前 `cd32c31` P6 加倍；`c7901ff` UX1–UX8 / Tag `v1.11.0`；`7cb0e62` Q1/P8-1/Q2；上一正式里程碑 `v1.10.0`）  
**仓库：** https://github.com/StormJx/blackjack-ios  
**平台：** iOS 17.0+；庄家小于 17 要牌、大于等于 17 停（软 17 同停）；音效基名 deal/flip/shuffle/win/lose/push

---

## 模式分工

| 模式 | 筹码 | 玩法道具 | 切牌 | 其它 |
|------|------|----------|------|------|
| 闯关 `.challenge` | 关卡进阶 | **禁用** | **设置三态**（每局重洗 / 仪式感 / 真实） | 成就 challenge 轨 |
| 娱乐 `.entertainment`（rawValue=`fast`） | **独立阶梯** + 注码随阶 | **可用** | **固定真实切牌** | 「同上局」；成就 practice 轨 |

成就分轨：娱乐不计入闯关成就。外观（卡背）跨模式可选用。开局全下解锁局数（F1）两模式共用设置。

---

## 已完成（v1.10 + 后续增量）

### 外观 / 设置 / 欢迎页
- [x] C1 卡背解锁 + 设置页选用（classicNavy / emeraldLattice / crimsonRibbon）
- [x] P4 桌限预设（标准/轻量/偏大）— **仅闯关新会话生效**；娱乐跟阶梯注码
- [x] P8 **深色**基础适配（对局 `TableBackgroundView` 跟随系统）
- [x] 欢迎页精简：牌桌绿底 + 游戏名 + 闯关/娱乐入口 + 帮助说明；顶栏成就/战绩/设置保留
- [x] `HelpView`：规则与模式说明迁入帮助；主页不再堆进度/道具/牌副文案
- [x] 开局牌副改读设置「默认牌副」（欢迎页无 Picker）
- [x] P5 切牌三态：`CutCardMode`（off / ceremonial / real）；设置 Picker；娱乐固定 real；旧布尔键可迁移
- [x] F1 全下解锁局数可配置（设置 Stepper 0–10，默认 5；`ActivePreDealAllInUnlock` 新会话生效；两模式共用）
- [x] **F2 战绩进度**：`StatsView` 展示闯关关 / 娱乐阶、起始筹码、下一门槛、娱乐累计；帮助文案指向战绩（欢迎页仍不堆进度）
- [x] **UX1**：欢迎页闯关/娱乐按钮下各一行短副文案（`PlayStyle.welcomeSubtitle`）

### 娱乐 / 道具 / 音效
- [x] 娱乐独立进阶 `EntertainmentProgress`（打穿或累计赢升阶；注码随阶）
- [x] P3 「同上局」下注（仅娱乐）
- [x] 娱乐固定真实切牌（设置切牌只影响闯关）
- [x] 道具：`midHandAllIn` / `dealerSoft17Hit` / `peekHole` / `redrawOne` / `reshuffleDealerCard`（仅娱乐，永久解锁）
- [x] `reshuffleDealerCard`：解锁 `practiceWins50`；每局限 1；随机含暗牌；窥视中禁用；牌面脉冲 +「已换庄家一张」；`shuffleHint`；**穿透净不变**；非空鞋不原样抽回
- [x] F10：六基名 wav 为 44.1kHz 高质量程序合成（**仍非录音正片**；可替换 `Sounds/`）
- [x] **UX2**：局内全下二次确认（设置可关，默认开）
- [x] **UX5**：娱乐局末展示本会话 `FastSessionStats`
- [x] **UX6**：窥视倒计时条 + 娱乐道具首次引导 alert
- [x] **UX7**：局末可「查看牌面」收起，再「显示结果」
- [x] **P6**：加倍（仅前两张 + 只补一张；闯关/娱乐；不足额禁用；不计入全下成就）
- [x] **P6+ 投降**：仅前两张；任意明牌；退半注（向下取整）；闯关/娱乐；记为输；全下禁用；主操作两行布局

### 成就 / 体验
- [x] **UX3**：局末解锁改为卡片队列（非长 toast）
- [x] **UX4**：成就页道具仅「娱乐」tab；闯关解锁道具标「去闯关解锁」
- [x] **UX8**：娱乐成就标题「练习」→「娱乐」

### 工程 / 无障碍
- [x] **Q1**：`ChipBank.sessionRoundsCompleted` 与筹码同 suite 持久化；杀进程后全下解锁进度保留；恢复提示文案同步；主动退出清空；单测
- [x] **P8-1** 无障碍第一切片：下注/局末可滚动 + 粘性主按钮；VoiceOver（点数/余额/注码/结果/要牌停牌/道具具体禁用原因）；欢迎标题动态字体；洗牌页尊重减弱动态效果；设置页去开发者音效文案
- [x] **Q2**：`GameTiming` / `GameFeedbackServing` 注入；`SessionConfiguration`；`cancelPendingWork()`；天然 BJ / hit 爆牌 / 软 17 默认停与道具要 / 牌尽 fallback 单测

### 规划入库（效果未接线）
- [x] P8 横竖屏 → 见 `docs/P8_ORIENTATION_AND_A11Y.md`（横屏仍后置）
- [x] 工程评审批次 backlog → `docs/ENGINEERING_REVIEW_BACKLOG.md`

---

## 未完成（须点名再做）

| 编号 | 内容 | 备注 |
|------|------|------|
| UX9 | 设置「对局中不生效」全局提示再统一 | 见 backlog |
| P8 横竖屏 | 允许横屏与布局 | 见 P8 文档 |
| F10 正片录音 | 录音级素材替换 | 基名不变 |
| C5 | 对道具战模式 | 须先锁产品 |
| P6+ | 保险 → 分牌（分牌最后） | 投降已落地；须锁规则 |
| 娱乐阶梯数值 | 试玩后再调 | 当前表保持 |
| 广告（上架） | 免费 + 轻度广告 | **仅备案**；插点/频控须另点名；见 backlog「产品方向」 |

**明确不做：** 闯关启用玩法道具；娱乐计入闯关成就；默认模式内独立「练习分」。

---

## 产品方向（简）

干净练习游戏；免费上 iOS 可轻度广告（后置）。广告不对局中打断；细则见 `ENGINEERING_REVIEW_BACKLOG.md`。

---

## 工程要点

- `PlayStyle` / `PropStore` / `ChallengeProgress` / `EntertainmentProgress` / `CosmeticsStore` / `TableLimitPreset` / `CutCardMode` / `ActivePreDealAllInUnlock` / `SessionConfiguration` / `HelpView` / `StatsView`
- `ChipBank`：会话起始筹码 + **本会话全下解锁局数**；退出清空；**P6** `doubleDown()`（足额再押；不置 `activeBetWasAllIn`）
- `BlackjackGame`：可注入 `GameTiming` / `GameFeedbackServing`；退出调用 `cancelPendingWork()`；**P6** `doubleDown()`；**P6+** `surrender()` → `RoundOutcome.playerSurrender`
- `RoundSettlement`：投降退半注（向下取整）
- `Deck.returnCardToShoe`：回退 `dealtCount`；非空鞋禁止立即原样抽回
- 推送前：`./scripts/check-before-push.sh`；勿提交 `VERSION_ROADMAP.txt` / `.env` / 密钥

---

## 建议下一步（按优先级）

1. 讨论 **P6+「保险」** 规则后单切片（分牌更后）  
2. **UX9**；或试玩后再调阶梯数值  
3. 广告上架方案后置专篇（已备案）  
4. P8 横竖屏 / C5 / F10 正片更后

**本批已推送：** `c5aa3ec`（P6+ 投降 + 主操作两行）。此前：`cd32c31`（P6 加倍）；`c7901ff`（UX1–UX8；Tag `v1.11.0`）；`7cb0e62`（Q1 / P8-1 / Q2）。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-23 | 初版检查点：对应 v1.10 推送交接 |
| 2026-07-23 | `reshuffleDealerCard` 接线（`practiceWins50`；仅娱乐） |
| 2026-07-23 | 换庄家体验：正向单测、牌面脉冲弱提示、窥视中禁用、道具两列网格 |
| 2026-07-23 | 欢迎页精简：牌桌绿 + 双入口 + HelpView；牌副改走设置默认；基线 `6ebe464` |
| 2026-07-25 | P5 切牌三态 + F1 全下解锁可配置 + F10 44.1kHz 合成音增强 |
| 2026-07-27 | 功能已推送 `c670180`；检查点基线同步 |
| 2026-07-27 | 换庄家牌堆边界；F2 战绩关/阶进度；新增 `ENGINEERING_REVIEW_BACKLOG`；P8 第一切片清单 |
| 2026-07-28 | 已推送 `d443bfa`；检查点基线同步 `3d575d6` |
| 2026-07-28 | 已推送 `7cb0e62`（Q1 / P8-1 / Q2）；检查点基线同步 |
| 2026-07-28 | 已推送 `c7901ff`（UX1–UX8）；Tag `v1.11.0`；检查点基线同步 |
| 2026-07-31 | 已推送 `cd32c31`（P6 加倍）；检查点基线同步 |
| 2026-08-01 | 产品方向备案：干净练习 + 免费可轻度广告（后置）；广告写入未完成表 |
| 2026-08-01 | 已推送 `c5aa3ec`（P6+ 投降 + 主操作两行）；检查点基线同步 |
