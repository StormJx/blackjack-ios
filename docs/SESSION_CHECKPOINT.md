# 会话检查点（可推送 GitHub）

> 本地另有 `VERSION_ROADMAP.txt`（gitignore，勿推送）。两边请同步维护。  
> 成就：`docs/ACHIEVEMENTS.md` · 外观道具：`docs/COSMETICS_AND_PROPS.md`  
> P8：`docs/P8_ORIENTATION_AND_A11Y.md` · 评审批次 backlog：`docs/ENGINEERING_REVIEW_BACKLOG.md`  
> 后续优化执行路线：`docs/OPTIMIZATION_GUIDE.md`（A 工程加固 / L 上架 / T 教学轨 / M 变现 / R 留存）

**基线：** `main` @ `c3df947`（v2.0：语言切换 + en 全量 + 隐私清单；检查点随后同步）  
工程版本：`MARKETING_VERSION = 2.0` / `CURRENT_PROJECT_VERSION = 2`  
已推送里程碑：绯红图标 + CI 英文本地 @ `3ae3e74`；L10n 回退 @ `6aa8c6b`；Tag `v1.11.1` @ `12234c5`（UX9）；L1 @ `398dc74`  

**仓库：** https://github.com/StormJx/blackjack-ios  
**平台：** iOS 17.0+；庄家小于 17 要牌、大于等于 17 停（软 17 同停）；音效基名 deal/flip/shuffle/win/lose/push  
**新窗交接提示词：** `docs/NEXT_SESSION_PROMPT.md`（复制其中「提示词正文」到新 Agent 会话即可）

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
- [x] **P6+ 保险**：仅庄家明 A；半注（向下取整）2:1；闯关/娱乐；全下禁；独立保险面板；Ace peek（有 BJ 直接结）；不做 Even Money；窥视仅玩家回合；侧注进 `SettlementResult` 合计盈亏

### 成就 / 体验
- [x] **UX3**：局末解锁改为卡片队列（非长 toast）
- [x] **UX4**：成就页道具仅「娱乐」tab；闯关解锁道具标「去闯关解锁」
- [x] **UX8**：娱乐成就标题「练习」→「娱乐」
- [x] **UX9**：设置页「生效时机」统一提示——牌副 / 切牌 / 桌限 / 全下解锁对局中不生效，须返回主页再开新局；变更时顶部高亮同文案；音效/触觉/全下确认/卡背可立即生效；HelpView 对齐

### 工程 / 无障碍
- [x] **Q1**：`ChipBank.sessionRoundsCompleted` 与筹码同 suite 持久化；杀进程后全下解锁进度保留；恢复提示文案同步；主动退出清空；单测
- [x] **P8-1** 无障碍第一切片：下注/局末可滚动 + 粘性主按钮；VoiceOver（点数/余额/注码/结果/要牌停牌/道具具体禁用原因）；欢迎标题动态字体；洗牌页尊重减弱动态效果；设置页去开发者音效文案
- [x] **Q2**：`GameTiming` / `GameFeedbackServing` 注入；`SessionConfiguration`；`cancelPendingWork()`；天然 BJ / hit 爆牌 / 软 17 默认停与道具要 / 牌尽 fallback 单测
- [x] **A1**：`SessionCoordinator` 抽取局末结算/成就/进度/卡背同步；欢迎页 `syncOnAppAppear` / `syncProgressAndCosmetics`；`SessionCoordinatorTests` 四类场景
- [x] **A2**：`DataSchema` 持久化版本号（**`currentVersion = 2`**）；`cardsApp.init` 在 Store 之前 `migrateIfNeeded`；改持久化结构须升版本并写 `runMigrations`；`DataSchemaTests`（v2：语言偏好为新键，缺省跟随系统，无数据改写）
- [x] **A3**：GitHub Actions CI（`.github/workflows/test.yml`：`macos-15`，push/PR 触发，动态解析 iPhone 模拟器，`-only-testing:cardsTests`，**`-testLanguage en -testRegion US`**）；补共享 scheme；无 secrets
- [x] **A4**：`BlackjackGame.recordBraveHitProgress(beforeBest:currentBest:)`；`hit` / `doubleDown` / `redrawLastHitCard` 共用
- [x] **L1**：`Localizable.xcstrings`（zh-Hans + **en 全量约 440 key**）+ `L10n.t` / `L10n.key` / `L10n.format`；缺译回退 zh-Hans；动态 key **必须** `L10n.key`
- [x] **L3 第一刀**：`PrivacyInfo.xcprivacy`（不追踪 / 无采集 / UserDefaults CA92.1）+ `PrivacyView`（设置「关于」/ 帮助）；Connect 问卷仍须按 `docs/APP_STORE.md` 勾选
- [x] **L5 上架素材**：`docs/APP_STORE.md`（副标题 / 描述 / 关键词 / 17+ / 隐私标签）；`docs/privacy.html` + `docs/GITHUB_PAGES.md`；6.9″ 截图脚本与样张；主屏幕名「二十一点」/ Blackjack
- [x] **语言切换**：设置「跟随系统 / 中文 / English」（`AppLanguagePreference`）；立即生效；与系统语言分轨
- [x] **App 图标**：绯红缎带牌背 45° 扇形铺开（1024、无透明）；正式资源 `AppIcon.appiconset/AppIcon.png`
- [x] **T1 基础策略表**：`BasicStrategy` 多副 S17 静态查表 + `BasicStrategyTests`；零 UI；输出要/停/加倍/投降/分牌

### 规划入库（效果未接线）
- [x] P8 横竖屏 → 见 `docs/P8_ORIENTATION_AND_A11Y.md`（横屏仍后置）
- [x] 工程评审批次 backlog → `docs/ENGINEERING_REVIEW_BACKLOG.md`

---

## 未完成（须点名再做）

| 编号 | 内容 | 备注 |
|------|------|------|
| ~~UX9~~ | ~~设置「对局中不生效」全局提示再统一~~ | **已完成**（见已完成节） |
| P8 横竖屏 | 允许横屏与布局 | 见 P8 文档 |
| F10 正片录音 | 录音级素材替换 | 基名不变 |
| C5 | 对道具战模式 | 须先锁产品 |
| P6+ | 分牌（多手状态机） | 投降+保险已落地；分牌最后 |
| 娱乐阶梯数值 | 试玩后再调 | 当前表保持 |
| 广告（上架） | 免费 + 轻度广告 | **仅备案**；插点/频控须另点名；见 backlog「产品方向」 |

**明确不做：** 闯关启用玩法道具；娱乐计入闯关成就；默认模式内独立「练习分」；**T2 局末复盘**。

---

## 产品方向（简）

**公平闯关为主**的干净练习游戏；娱乐道具分轨保留但不作为商店主卖点。免费上 iOS，轻度广告后置。广告不对局中打断；细则见 `ENGINEERING_REVIEW_BACKLOG.md`。

---

## 工程要点

- `PlayStyle` / `PropStore` / `ChallengeProgress` / `EntertainmentProgress` / `CosmeticsStore` / `TableLimitPreset` / `CutCardMode` / `ActivePreDealAllInUnlock` / `SessionConfiguration` / `SessionCoordinator` / `DataSchema` / `HelpView` / `StatsView`
- **持久化约定：** 改 UserDefaults 键/语义时递增 `DataSchema.currentVersion` 并在 `runMigrations` 补迁移
- `ChipBank`：会话起始筹码 + **本会话全下解锁局数**；退出清空；**P6** `doubleDown()`（足额再押；不置 `activeBetWasAllIn`）；**P6+** `placeInsurance()` / `activeInsurance`（中断退回）
- `BlackjackGame`：可注入 `GameTiming` / `GameFeedbackServing`；退出调用 `cancelPendingWork()`；**P6** `doubleDown()`；**P6+** `surrender()` → `RoundOutcome.playerSurrender`；**P6+** `phase.insuranceOffer` + `resolveInsuranceDecision` + Ace peek → `lastInsuranceWon`
- `RoundSettlement`：投降退半注（向下取整）；保险侧注先于主注结算（2:1 / 未中）
- `SessionInsurancePanel`：买保险 / 不买
- `Deck.returnCardToShoe`：回退 `dealtCount`；非空鞋禁止立即原样抽回
- CI：`.github/workflows/test.yml`（仅 `cardsTests`）；共享 scheme 须入库
- **L10n：** `Localizable.xcstrings`（zh-Hans + en）+ `L10n`；设置可覆盖语言；扩语言只补 catalog；动态 key 用 `L10n.key`
- **T1：** `BasicStrategy` / `StrategyHand` / `StrategyAction`；多副、庄家软 17 停、晚投降；不可用动作走表内回退
- **隐私：** `PrivacyInfo.xcprivacy` + `PrivacyView` + `docs/privacy.html`；Pages 步骤见 `docs/GITHUB_PAGES.md`；版本展示读 `CFBundleShortVersionString`（2.0）
- **L5：** `docs/APP_STORE.md`；主屏幕 `CFBundleDisplayName`；截图 `store/screenshots/iphone-69/`
- 推送前：`./scripts/check-before-push.sh`；勿提交 `VERSION_ROADMAP.txt` / `.env` / 密钥
- 单测：一次一个 `xcodebuild`，日志落文件，避免叠多个模拟器

---

## 建议下一步（按优先级）

1. 按 `docs/GITHUB_PAGES.md` 发布隐私页，并在 Connect 粘贴 L5 文案 / 截图 / 17+ / 隐私标签（见 `docs/APP_STORE.md`）  
2. **L2 分牌**须先锁产品；帮助已写明本版暂不分牌  
3. 更后：T3 正确率 / T4 实时提示 / T5 算牌（均须点名）；广告专篇 / P8 横屏 / C5 / F10 正片 / A5  
4. **T2 局末复盘已取消**，勿再排期  

**交接：** `NEXT_SESSION_PROMPT.md` · 路线：`OPTIMIZATION_GUIDE.md`。

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
| 2026-08-01 | 已推送 `ef95b0c`（P6+ 保险）+ `9743d0c`（检查点同步）；新增 `NEXT_SESSION_PROMPT.md` |
| 2026-08-01 | UX9：设置「生效时机」统一提示；`OPTIMIZATION_GUIDE.md` 入库；建议下一刀 A1 |
| 2026-08-01 | 已推送 `12234c5` / Tag `v1.11.1`；检查点基线同步 |
| 2026-08-01 | A1：`SessionCoordinator` + 单测；建议下一刀 A2 |
| 2026-08-01 | A2：`DataSchema` + 单测；建议下一刀 A3；A1+A2 待统一提交 |
| 2026-08-01 | A1+A2 统一提交 `94d2ddb`；更新 `NEXT_SESSION_PROMPT.md`；检查点基线同步 |
| 2026-08-01 | A3：GitHub Actions CI + 共享 `cards` scheme @ `91f1f4c`；push 后确认 Actions 绿 |
| 2026-08-02 | A4：`recordBraveHitProgress` 去重 @ `0385e2a`；建议下一刀讨论 L1 |
| 2026-08-04 | L1：String Catalog + 三刀迁移 @ `398dc74`；检查点 `0fa80e6` 已推送；动态 key 用 `L10n.key` |
| 2026-08-05 | L10n 英文本地缺译回退 @ `6aa8c6b` |
| 2026-08-30 | 绯红扇形牌背图标 + CI `-testLanguage en` @ `3ae3e74` |
| 2026-08-30 | v2.0 功能 @ `c3df947`：公平闯关定位；语言切换；en 全量；PrivacyInfo + PrivacyView；DataSchema=2 |
| 2026-08-30 | T1：`BasicStrategy` + 单测；**T2 局末复盘取消**（文档计划删除，无实现代码） |
| 2026-08-30 | L5：商店填写稿 + 隐私静态页 + 6.9″ 截图；Connect 勾选仍须用户提交 |
| 2026-08-30 | 隐私页迁至 `docs/privacy.html`，Pages 步骤见 `docs/GITHUB_PAGES.md` |

