# 后续优化执行指南（可推送 GitHub）

> 来源：2026-08-01 工程 / 产品 / 商业三层分析。  
> 会话检查点：`docs/SESSION_CHECKPOINT.md` · 评审 backlog：`docs/ENGINEERING_REVIEW_BACKLOG.md`  
> **执行纪律与其它文档一致：未点名不实现；一次一刀（切片）；改完补测 → `./scripts/check-before-push.sh` → 用户要求才 commit/push。**  
> 编号前缀：`A` 工程加固 / `L` 上架准备 / `T` 教学轨 / `M` 变现 / `R` 留存（避开既有 UX / P / C / F / Q 编号）。

---

## 总路线（推荐执行顺序）

| 顺序 | 阶段 | 内容 | 前置 |
|------|------|------|------|
| 0 | 既定 backlog | ~~UX9 设置提示统一~~ **已完成** | — |
| 1 | A 工程加固 | ~~A1~~ ~~A2~~ ~~A3~~ ~~A4~~ **已完成** → A5 可穿插（C5/新道具前）；A6 长线 | — |
| 2 | L 上架准备 | ~~L1~~ **已完成（含 en 全量 + 语言切换）** → L3 第一刀已完成（PrivacyInfo + 应用内说明）→ **L5 素材 / 提审标签**；L2 分牌仍须先锁产品 | A2 已完成 |
| 3 | T 教学轨 | T1 策略引擎 → T2 局末复盘 → T3 正确率统计 → T4 实时提示 → T5 算牌训练 | A1（复盘挂局末编排） |
| 4 | M 变现 | M1 广告 → M2 去广告 IAP → M3 外观 IAP | L3（ATT/隐私） |
| 5 | R 留存 | R1 每日挑战 → R2 iCloud 同步 | 上架后迭代 |

原则：**每个切片独立可验收、可回滚**；跨切片不顺手重构；分牌（L2）动状态机前必须先完成 A1，避免在「上帝视图」上继续叠复杂度。

---

## 阶段 A · 工程加固

### A1 抽取 `SessionCoordinator`（最高优先级）

**问题**：`ContentView.swift` 内 `GameSessionView` 约 680 行，`handleRoundFinished()` / `settleCurrentRoundIfNeeded()` 混合结算、成就记录、道具/卡背/关卡同步、解锁通知五件事；`syncFromStats` + `syncFromProgress` 组合在文件内重复约 5 处；这段最易错的编排逻辑目前**无单测**。

**步骤**：
1. 新建 `cards/SessionCoordinator.swift`：`@MainActor final class SessionCoordinator: ObservableObject`，注入 `ChipBank` / `StatsStore` / `PropStore` / `ChallengeProgress` / `EntertainmentProgress` / `CosmeticsStore` / `playStyle`。
2. 迁入并合并四分支逻辑（闯关/娱乐 × 有无 snapshot）：
   - `settleRound(outcome:insuranceWon:)` — 结算 + 记账 + 进度同步；
   - `recordRoundFinished(snapshot:sessionEndReason:)` — 成就 / 打穿 / 道具 / 卡背同步，返回 `[String]` 解锁通知；
   - `syncProgressAndCosmetics()` — 收敛重复的 sync 组合调用（含 `onAppear` / `onEndSession` 两处）。
3. `GameSessionView` 只保留：调用 coordinator、驱动面板显隐、动画。
4. 补单测（新文件 `cardsTests/SessionCoordinatorTests.swift`）：
   - 闯关赢局 → 记账 + 关卡/卡背同步被调用；
   - 娱乐打穿 → `EntertainmentProgress.recordDealerCleared` 且**不**触发闯关成就；
   - 保险赔付局的净盈亏传递；
   - 中途退出（无 outcome）→ 退注不记局。

**验收**：局末编排迁入 `SessionCoordinator` 并可单测；行为与现状完全一致；覆盖闯关赢局 / 娱乐打穿隔离 / 保险净盈亏 / 无 outcome 退注。  
（注：`GameSessionView` UI 仍约 600 行；进一步拆面板见 A5，不在本刀强行削到 300。）  
**规模**：中（1–2 刀）。**风险**：中——纯搬移，勿顺手改逻辑。  
**状态：已完成（2026-08-01）**

### A2 持久化 schema 版本号

**问题**：`UserDefaults` 键散布在 `ChipBank` / `StatsStore` / `PropStore` / 两个 Progress / `CosmeticsStore`，无版本标记；上架后改成就结构或阶梯表将无法安全迁移老用户数据。

**步骤**：
1. 新建 `cards/DataSchema.swift`：`dataSchemaVersion` 键（起始 `1`）+ `migrateIfNeeded()` 入口（当前为空实现，仅写入版本号）。
2. `cardsApp.swift` 启动时调用。
3. 在本文件与 `SESSION_CHECKPOINT.md` 约定：**凡改动持久化结构，必须递增版本并在 `migrateIfNeeded` 写迁移**。
4. 单测：首启写入版本；已有版本不重写；模拟低版本 → 迁移钩子被调用。

**验收**：新装与升级路径单测通过。**规模**：小（半刀）。**风险**：低。  
**状态：已完成（2026-08-01）** — `DataSchema.migrateIfNeeded()` 在 `cardsApp.init` 于各 Store 之前调用；`DataSchemaTests` 覆盖三路径。  
**2026-08-30：** `currentVersion = 2`（语言偏好新键，缺省跟随系统，step 2 无数据改写）。

### A3 GitHub Actions CI

**步骤**：
1. 新建 `.github/workflows/test.yml`：macOS runner，`xcodebuild test -scheme cards -destination 'platform=iOS Simulator,name=iPhone 15'`（scheme/模拟器名以工程实际为准）。
2. push / PR 触发；缓存 DerivedData 可后补。
3. 确认工作流**不需要**任何 secrets（本工程无密钥依赖）；`VERSION_ROADMAP.txt` 已 gitignore，不会进 CI。

**验收**：main 上跑绿一次。**规模**：小。**风险**：低。  
**状态：已完成（2026-08-01）** — `.github/workflows/test.yml`（`macos-15`，动态解析 iPhone 模拟器，`-only-testing:cardsTests`）；补共享 scheme `cards.xcodeproj/xcshareddata/xcschemes/cards.xcscheme`（原先仅用户态，CI 会找不到）；本地 `xcodebuild test` 已绿。推送后须确认 Actions 跑绿。

### A4 成就判定去重（顺手刀）

`BlackjackGame.hit()` / `doubleDown()` / `redrawLastHitCard()` 三处重复的「险中求胜」判定（`beforeBest > 17/18/19`、`20→21`）抽成私有 `recordBraveHitProgress(beforeBest:currentBest:)`。既有单测保护，无需新增。**规模**：极小，可搭任意一刀。  
**状态：已完成（2026-08-02）** — 三处改为调用 `recordBraveHitProgress`；`braveHitLadderRequiresWin` + `BlackjackGameLogicTests` 已绿。

### A5 `GameTableView` 道具参数收敛

**问题**：约 30 个入参，每个道具重复 `shows / can / disabledReason / onAction` 四件套；C5 对道具战与候选道具落地前会继续膨胀。

**步骤**：
1. 新建 `PropControlDescriptor`（id / 标题 / 图标 / isVisible / isEnabled / disabledReason / isActive / action）。
2. `GameSessionView` 组装 `[PropControlDescriptor]`，`GameTableView` 道具区改为遍历渲染；要牌/停牌/加倍/投降主操作**不动**。
3. VoiceOver 标签与禁用原因逐一对齐现状（P8-1 成果不得回退）。

**验收**：UI 与读屏行为无变化；`GameTableView` 入参明显减少。**规模**：中（1 刀）。**建议时机**：C5 或新道具立项前做，否则可延后。

### A6 收敛 `SessionConfiguration.applyToProcessGlobals()`（长线）

进程级全局可变状态是时序 bug 温床（尤其未来第三入口「对道具战」）。方向：`ChipRules` 相关读数改为实例化配置注入 `ChipBank` / 面板。**不单独立项**，与 C5 或分牌绑定实施；在此备案防遗忘。

---

## 阶段 L · 上架准备

### L1 本地化底座（String Catalog）

**问题**：全部字符串硬编码中文，`String(localized:)` 使用为零；越晚迁移成本越高。

**步骤**：
1. 工程加 `Localizable.xcstrings`；开 `SWIFT_EMIT_LOC_STRINGS`。
2. 分批迁移（每批一刀，避免巨型 diff）：① 欢迎页/设置/帮助 → ② 牌桌/面板/道具禁用原因 → ③ 成就/战绩标题文案。
3. 中文为源语言；英文翻译可后置，但 key 化必须完成。
4. 注意拼接文案（如 `"解锁\(title)"`、点数读法）改用带插值的 format key。

**验收**：源码无面向用户的裸中文字面量（`rg` 抽查）；UI 显示与现状一致。**规模**：中（2–3 刀）。  
**状态：已完成（2026-08-04；2026-08-30 补全）** — `Localizable.xcstrings`（`sourceLanguage=zh-Hans`，**en 约 440 key**）+ `L10n.t` / `L10n.key` / `L10n.format`；缺译回退 zh-Hans；设置「跟随系统 / 中文 / English」。动态 key 必须用 `L10n.key`。`developmentRegion=zh-Hans`。CI 锁定 `-testLanguage en`。

### L2 P6+ 分牌（既有 backlog 项，上架前建议提优）

懂玩法的用户会把「不能分对子」视为硬伤，直接影响首批评价。**前置：A1 完成；产品规则先锁**（须点名讨论后再动手），建议锁定范围：
- 仅同点数两张可分；分后每手独立要牌/停牌；A 分牌每手只补一张；
- 分牌后无天然 BJ（21 按普通 21）；再分牌（re-split）第一版**不做**；
- 分牌 + 加倍可叠加、分牌 + 投降/保险互斥关系须逐条确认；
- 全下与分牌互斥（余额不足第二注则禁用）。

**实现要点**：`BlackjackGame` 引入 `playerHands: [Hand状态]` + 当前手指针；`ChipBank` 支持多注；`RoundSettlement` 按手结算再汇总；UI 双手牌区 + 当前手高亮。**必须**补全套单测。**规模**：大（3–4 刀：状态机 → 结算 → UI → 收尾）。

### L3 合规与隐私

1. 年龄分级：含模拟赌博按 17+ 申报；**首发市场建议港台/东南亚/欧美，大陆区另行评估**（模拟赌博审核极严）。
2. 隐私政策页（可静态网页）+ App Store 隐私标签（当前无采集，如实申报；接广告/统计后同步更新）。
3. 接广告时补 ATT 弹窗与 `NSUserTrackingUsageDescription`（与 M1 绑定）。

### L4 隐私友好的轻量统计

backlog「阶梯数值试玩后再调」需要数据支撑。第一版**不接三方 SDK**：本地记录关卡到达率 / 各阶停留局数 / 破产率，`StatsView` 加开发者可见的导出（或调试面板）。后续若接 TelemetryDeck 类隐私友好方案，须另行点名。**规模**：小–中。

### L5 上架素材

App 图标全尺寸、截图（6.7"/6.1" 必备）、副标题与关键词（结合 T 阶段做「trainer / basic strategy」长尾词）、预览文案。纯执行项，放在提审前一刀完成。

---

## 阶段 T · 教学轨（产品差异化核心）

> 定位从「玩」扩到「学」，是本品类可防御的卖点；全部功能**默认不打扰**现有玩法。

### T1 基础策略引擎

1. 新建 `cards/BasicStrategy.swift`：输入（玩家手：硬点/软点/对子 × 庄家明牌 × 可加倍/可投降），输出建议动作（要/停/加倍/投降/分牌）。
2. 采用与本作规则一致的表：**多副、庄家软 17 停牌**版本基础策略；表数据写成静态查表，禁止散落 if-else。
3. 纯逻辑零 UI；全表单测（至少覆盖：硬 8–17 × 庄 2–A 抽样、软 13–20、对子表全行、投降格）。

**规模**：中（1 刀）。这是 T2–T4 的地基。

### T2 局末决策复盘

1. `BlackjackGame` 记录本局玩家每次决策的快照（决策时手牌 + 庄家明牌 + 所选动作）。
2. 局末面板（`SessionRoundEndPanel`）加可折叠「本局复盘」：逐决策对照 T1 建议，标注一致/偏离。
3. 仅展示，不改结算；闯关/娱乐都可用（纯信息，不破坏公平性）；设置可关。

**验收**：加倍/投降/道具改变手牌后的复盘均正确；VoiceOver 可读。**规模**：中（1–2 刀）。

### T3 决策正确率统计

`StatsStore` 累计「符合基础策略的决策数 / 总决策数」（分轨），`StatsView` 展示正确率与近期趋势；持久化改动走 A2 的版本迁移。**规模**：小–中。

### T4 实时提示开关（默认关）

设置项「行动建议」：开启后玩家回合主操作区显示 T1 建议（弱样式，不遮挡）。默认关闭，保持挑战性；闯关模式是否允许由用户点名裁定。**规模**：小。

### T5 算牌训练（Hi-Lo）

`Deck` 已有真实渗透/切牌点/剩余张数，边际成本低：
1. `CardCounting.swift`：Hi-Lo 每张牌的计数值 + running count 累计（单测全 52 张）。
2. 娱乐模式可选「算牌练习」：局间弹小测「当前 running count？」三选一，答对记录连对；战绩页展示。
3. 不与筹码经济挂钩（纯练习），避免赌博暗示。

**规模**：中（1–2 刀）。ASO 关键词价值高（"card counting practice"）。

---

## 阶段 M · 变现（守既定红线）

> 红线：仅局间/会话边界；对局中不打断；闯关轨少打扰；**绝不做「广告/付费换筹码」**。

### M1 轻度插屏广告
- 插点：仅「会话结束返回主页」与「连续 N 局后的局间」（N ≥ 5，可远端/本地配置频控）；闯关轨频率减半或不投。
- 接入 SDK 前完成 L3 的 ATT 与隐私标签更新；SDK 选型（AdMob 等）须点名后定。

### M2 去广告买断 IAP
- StoreKit 2；单档非消耗型；恢复购买入口在设置页。购买后 M1 全部插点关闭。

### M3 外观 IAP（第二收入，最干净）
- `CosmeticsStore` 架子已在：新增付费卡背组（非消耗型，2–3 组），与成就解锁卡背并存展示、来源标注区分；**不碰赔率与牌值**。

顺序：M1 与 M2 同一刀上线（有广告必须同时有去广告）；M3 独立。

---

## 阶段 R · 留存（上架后迭代）

### R1 每日挑战 / 连续打卡
每日一组目标（如「娱乐赢 3 局」「零爆牌完成 5 局」），完成给外观类或纯徽章奖励；连续天数展示在战绩页。**不给筹码**。

### R2 iCloud 进度同步
`NSUbiquitousKeyValueStore` 同步成就/进度/外观（数据量小，够用）；冲突策略取进度较高者。用户投入几十小时后换机丢档 = 一星差评，建议上架后 3 个月内完成。**前置：A2 版本迁移已就绪。**

---

## 明确不做（沿用既有裁定）

- 卖筹码 / 广告换筹码；闯关启用玩法道具；娱乐计入闯关成就
- 全面 MVVM 重写 / SwiftData / `Deck.removeFirst` 性能优化
- 账号体系 / 排行榜（R2 仅同步不社交）；100% 覆盖率与重量级 UI 快照

---

## 每刀通用验收清单

1. 既有单测全绿；可单测逻辑已补测。
2. 未越切片范围（无顺手重构）。
3. VoiceOver / 动态字体不回退（涉 UI 时抽查）。
4. `./scripts/check-before-push.sh` 通过；`VERSION_ROADMAP.txt` 未被跟踪。
5. `SESSION_CHECKPOINT.md` 与本文件勾选状态同步；用户点名后才 commit/push。

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-08-01 | 初版：A/L/T/M/R 五阶段路线入库；顺序 UX9 → A → L → T → M → R |
| 2026-08-01 | UX9 完成（`AppSettings.sessionLockedSettingsHint` + 设置页「生效时机」）；下一刀建议 A1 |
| 2026-08-01 | A1 完成：`SessionCoordinator` + `SessionCoordinatorTests`；下一刀建议 A2 |
| 2026-08-01 | A2 完成：`DataSchema` + `DataSchemaTests`；下一刀建议 A3 |
| 2026-08-01 | A3 完成：GitHub Actions CI + 共享 `cards` scheme；下一刀建议 A4 搭刀或 L1 / 保险抽查 |
| 2026-08-02 | A4 完成：`recordBraveHitProgress` 去重；可谈 L1 本地化；A5 仍延后至 C5/新道具前 |
| 2026-08-04 | L1 完成：String Catalog + 三刀文案迁移；欢迎页英文化；动态 key 用 `L10n.key` |
| 2026-08-30 | v2.0：en 全量 + 语言切换；L3 第一刀 PrivacyInfo / PrivacyView；建议下一刀 T1 |
