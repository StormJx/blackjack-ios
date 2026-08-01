# 新会话交接提示词（复制下方「提示词正文」整段到新 Agent 窗口）

> 维护说明：功能切片推送后请同步改本文件基线 / 已完成 / 建议下一刀。  
> 配套：`docs/SESSION_CHECKPOINT.md` · `docs/OPTIMIZATION_GUIDE.md` · `VERSION_ROADMAP.txt`（本地）· `docs/ENGINEERING_REVIEW_BACKLOG.md`

---

## 提示词正文（自下一行起复制）

```
你是 iOS（SwiftUI + Swift）开发助手。工作区是 blackjack-ios 工程。
仓库根目录有本地文件 VERSION_ROADMAP.txt（已 gitignore，勿推送 GitHub）。
请先阅读：docs/SESSION_CHECKPOINT.md、docs/OPTIMIZATION_GUIDE.md、VERSION_ROADMAP「当前检查点」、
docs/ENGINEERING_REVIEW_BACKLOG.md、docs/ACHIEVEMENTS.md、docs/COSMETICS_AND_PROPS.md、
docs/P8_ORIENTATION_AND_A11Y.md。用中文回复。

================================================================================
一、当前基线
================================================================================
GitHub：https://github.com/StormJx/blackjack-ios
分支 main（以 git log -1 为准；推送前可能仍 ahead of origin）
  - 已推送里程碑：Tag `v1.11.1` @ `12234c5`（UX9 + OPTIMIZATION_GUIDE）
  - 本批本地：A1 SessionCoordinator + A2 DataSchema（与检查点/本提示词同批提交）
  - 更早：`ef95b0c` 保险；`c5aa3ec` 投降；`cd32c31` 加倍；`c7901ff` UX1–UX8 / Tag `v1.11.0`
iOS 最低 17.0；庄家 <17 要牌、≥17 停（软 17 同停）；GameFeedback 音效基名约定不变
  （deal/flip/shuffle/win/lose/push；缺文件静默跳过）。
推送前须跑 ./scripts/check-before-push.sh；禁止提交 VERSION_ROADMAP.txt / .env / 密钥。
未点名勿擅自大改；可单测逻辑须补测。
后续优化按 docs/OPTIMIZATION_GUIDE.md 路线执行（一次一刀）。

--------------------------------------------------------------------------------
产品方向（重要）
--------------------------------------------------------------------------------
- 主定位：干净练习游戏（公平闯关 + 道具娱乐分轨），继续打磨进度 / 规则。
- 上架计划：免费上 iOS；可插入轻度广告（仅备案，未点名不接 SDK）。
- 广告约束（后置专篇）：仅局间/会话边界；对局中不打断；闯关轨少打扰；勿做成社交赌场式「广告换筹码逼氪」。
- 变现以后可考虑「去广告」买断或卡背包，不做卖筹码。

--------------------------------------------------------------------------------
模式分工（重要）
--------------------------------------------------------------------------------
- PlayStyle.challenge「闯关挑战」：关卡进阶；玩法道具禁用；切牌跟设置三态（CutCardMode）。
- PlayStyle.entertainment「娱乐模式」（rawValue 仍为 fast）：独立 EntertainmentProgress 阶梯
  （打穿或累计赢升阶；注码随阶）；已解锁玩法道具可用；固定真实切牌；「同上局」可用。
- 成就仍分轨：challenge / practice（娱乐计入 practice 轨；界面文案为「娱乐」）。
- 外观（卡背）可跨模式选用。桌限预设 P4 仅影响闯关；娱乐注码跟阶梯。
- 开局全下解锁局数（F1）两模式共用设置（0–10，默认 5；ActivePreDealAllInUnlock 新会话生效）。
- 欢迎页：牌桌绿底 +「二十一点」+ 闯关/娱乐入口（各一行短副文案）+「帮助说明」(HelpView)；
  顶栏成就/战绩/设置保留。规则与进度说明在帮助/战绩里，不在主页堆文案。
- 开局牌副读设置「默认牌副」（欢迎页无 Picker）。
- 关卡/阶梯进度在 StatsView（F2 已完成），勿塞回欢迎页。

--------------------------------------------------------------------------------
已完成（细节以 docs/SESSION_CHECKPOINT.md / OPTIMIZATION_GUIDE 为准）
--------------------------------------------------------------------------------
【至 v1.11.1】核心玩法、筹码、道具、卡背、闯关/娱乐进阶、Q1/P8-1/Q2、UX1–UX9、
P6 加倍、P6+ 投降/保险、OPTIMIZATION_GUIDE 入库。

【UX9 @ v1.11.1】设置页「生效时机」：对局中修改不生效，返回主页后新开局生效；
牌副/切牌/桌限/全下解锁变更高亮同文案；音效/触觉/全下确认/卡背可立即生效。

【A1 SessionCoordinator】
- cards/SessionCoordinator.swift：settleRound / recordRoundFinished / finishRound
- syncProgressAndCosmetics / syncOnAppAppear（欢迎页 onAppear / onEndSession 收敛）
- GameSessionView 局末改调 coordinator；行为与抽前一致
- cardsTests/SessionCoordinatorTests：闯关赢局记账、大赢升关+卡背、娱乐打穿不碰闯关、
  保险净盈亏 0、无 outcome 退注不记局
- 注：GameSessionView UI 仍约 600 行；进一步拆面板见指南 A5，不在 A1 强行削行数

【A2 DataSchema】
- cards/DataSchema.swift：currentVersion = 1；键 dataSchema.version
- migrateIfNeeded → freshInstall / alreadyCurrent / migrated；runMigrations 分步钩子
- cardsApp.init：先 DataSchema.migrateIfNeeded()，再创建各 Store（迁移须在读盘前）
- 约定：改 UserDefaults 键/语义必须递增 currentVersion 并写 applyMigrationStep
- cardsTests/DataSchemaTests：三路径 + runMigrations 安全

【P6+ 保险 @ ef95b0c】（已锁定，勿擅自改）明 A；半注 2:1；Ace peek；全下禁；无 Even Money

================================================================================
二、待后续完成（须用户点名后再做）— 见 OPTIMIZATION_GUIDE
================================================================================
优先建议：
1. A3 GitHub Actions CI（推荐下一刀；小切片）— .github/workflows/test.yml，xcodebuild test
2. 可选：保险路径实机抽查；有 bug 再修
3. A4 成就判定去重（可搭刀）/ A5 GameTableView 道具参数收敛（新道具或 C5 前）
4. L1 本地化 String Catalog（上架准备）；L2 分牌须先锁产品
5. T 教学轨（基础策略引擎等）— 差异化，但后置于工程 A3 / 上架准备讨论
6. 广告专篇 / P8 横屏 / C5 / F10 正片 — 更后

其它后置：见 docs/ENGINEERING_REVIEW_BACKLOG.md 与 docs/OPTIMIZATION_GUIDE.md

已明确取消、勿再做：
  - 默认模式内独立「练习分」
  - 把娱乐对局计入闯关成就
  - 在闯关模式启用玩法道具
  - 本刀不做 Even Money（除非用户重新点名讨论）
  - 卖筹码 / 广告换筹码

================================================================================
三、本会话工作方式
================================================================================
1. 先确认已读 SESSION_CHECKPOINT / OPTIMIZATION_GUIDE / ENGINEERING_REVIEW_BACKLOG /
   路线图检查点 / 成就与道具 / P8，用简短中文复述基线与待做项。
2. 与用户从第二节点名后再实现；未点名不改；按 OPTIMIZATION_GUIDE 一次一刀。
3. 若做道具：仅娱乐模式接线；闯关保持禁用。
4. 若做卡背：只做外观选用/解锁，不改赔率与牌值。
5. 改持久化结构：必须升 DataSchema.currentVersion 并写迁移。
6. 改完：可单测补测 → check-before-push.sh → 用户要求才 commit/push；
   勿提交 VERSION_ROADMAP.txt。
7. 额外体验优化单独罗列，便于验收。
8. 欢迎页保持简洁；说明进 HelpView / StatsView。
9. 一个功能切片结束后建议用户同步检查点；用户要求 push 前必须跑 check-before-push.sh。

请先确认已读上述内容，然后等待我点名要讨论或要实现的项。
（建议下一刀：A3 GitHub Actions CI；见 docs/OPTIMIZATION_GUIDE.md。）
```

---

## 建议下一步（给维护者，不必贴进新窗）

| 优先级 | 项 | 为何现在做 | 步骤提纲 |
|--------|----|------------|----------|
| 1 | **A3** | 无 CI，回归靠本地 | 见 `docs/OPTIMIZATION_GUIDE.md` A3；模拟器名以本机 `xcrun simctl` 为准（常用 iPhone 16） |
| 2 | 保险实机抽查 | 防回归 | 明 A 买/不买；全下禁买；peek 后窥视；庄家 BJ 盈亏约 0 |
| 3 | A4 / A5 | 小清理 / 参数收敛 | 可搭刀或 C5 前做 A5 |
| 4 | L1 本地化 | 上架准备 | String Catalog 分批迁移 |
| 5 | L2 分牌 | 须先产品锁 | 多手状态机；见 OPTIMIZATION_GUIDE L2 |
| 后置 | T 教学轨 / 广告 / 横屏 / C5 / F10 | 产品或素材未齐 | 未点名不接 SDK |

**明确不做：** 闯关开道具；娱乐进闯关成就；独立练习分；未讨论就做 Even Money / 分牌；卖筹码。
