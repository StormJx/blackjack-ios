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
分支 main；工程 MARKETING_VERSION = 2.0 / CURRENT_PROJECT_VERSION = 2
  - 本批：v2.0 公平闯关定位 + 语言切换 + en 全量 + PrivacyInfo / PrivacyView + DataSchema=2
  - 图标：绯红扇形牌背 @ `3ae3e74`
  - L10n 英文本地缺译回退 @ `6aa8c6b`
  - 更早：L1 @ `398dc74`；Tag `v1.11.1` @ `12234c5`（UX9）；A4 @ `0385e2a`/`6829d42`；
    A3 @ `91f1f4c`/`8c2db15`；A1+A2 @ `94d2ddb`；保险 `ef95b0c`；投降 `c5aa3ec`；加倍 `cd32c31`
iOS 最低 17.0；庄家 <17 要牌、≥17 停（软 17 同停）；GameFeedback 音效基名约定不变
  （deal/flip/shuffle/win/lose/push；缺文件静默跳过）。
推送前须跑 ./scripts/check-before-push.sh；禁止提交 VERSION_ROADMAP.txt / .env / 密钥。
未点名勿擅自大改；可单测逻辑须补测。
后续优化按 docs/OPTIMIZATION_GUIDE.md 路线执行（一次一刀）。
跑 xcodebuild / 单测时一次只开一个进程，日志落到文件，避免叠多个模拟器拖垮机器。
CI：macos-15；仅 cardsTests；必须带 -testLanguage en -testRegion US。

--------------------------------------------------------------------------------
产品方向（重要）
--------------------------------------------------------------------------------
- 主定位：**公平闯关为主**的干净练习游戏；娱乐道具分轨保留，不作商店主卖点。
- 上架：免费上 iOS；轻度广告仅备案（未点名不接 SDK）。
- 广告约束（后置）：仅局间/会话边界；对局中不打断；闯关轨少打扰；不做「广告换筹码」。
- 变现以后可考虑「去广告」买断或卡背包，不卖筹码。
- 帮助已写明：本版规则为简化赌场二十一点，暂不分牌。

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
- 设置语言：跟随系统 / 中文 / English（AppLanguagePreference）；立即生效。
- App 图标：绯红缎带牌背、约 45° 扇形、只露背面。

--------------------------------------------------------------------------------
已完成（细节以 docs/SESSION_CHECKPOINT.md / OPTIMIZATION_GUIDE 为准）
--------------------------------------------------------------------------------
【至 v1.11.1】核心玩法、筹码、道具、卡背、闯关/娱乐进阶、Q1/P8-1/Q2、UX1–UX9、
P6 加倍、P6+ 投降/保险、OPTIMIZATION_GUIDE 入库。

【A1 SessionCoordinator】局末结算/成就/进度可单测；欢迎页 sync 收敛。
【A2 DataSchema】currentVersion=2；Store 前迁移；改持久化须升版本。
【A3 CI】macos-15；cardsTests；-testLanguage en -testRegion US。
【A4】recordBraveHitProgress 险中求胜判定去重。

【L1 / 语言 @ v2.0】
- Localizable.xcstrings：zh-Hans + en，约 440 key
- L10n.t / L10n.key / L10n.format；缺译回退 zh-Hans
- 设置可覆盖语言；动态 key 必须 L10n.key（禁止 LocalizationValue("a.\(id).b") 插值）
- 扩语言：只改 xcstrings；勿再散落硬编码中文

【L3 第一刀】PrivacyInfo.xcprivacy + PrivacyView；无账号/无追踪/无对局中广告。
  提审时仍须填商店年龄分级与隐私标签。

【P6+ 保险 @ ef95b0c】（已锁定，勿擅自改）明 A；半注 2:1；Ace peek；全下禁；无 Even Money

================================================================================
二、待后续完成（须用户点名后再做）— 见 OPTIMIZATION_GUIDE
================================================================================
优先建议：
1. T1 基础策略表（无 UI，多副、庄家软 17 停；静态查表 + 单测）
2. T2 局末复盘（默认关；挂 SessionCoordinator）
3. L5 上架截图 / 副标题；提审填 17+ 与隐私标签
4. L2 分牌须先锁产品（见 OPTIMIZATION_GUIDE L2）
5. 更后：广告专篇 / P8 横屏 / C5 / F10 正片 / A5（新道具前）

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
5. 改持久化结构：必须升 DataSchema.currentVersion 并写迁移（当前为 2）。
6. 改用户可见文案：走 Localizable.xcstrings + L10n；动态 key 用 L10n.key；中英都补。
7. 改完：可单测补测 → check-before-push.sh → 用户要求才 commit/push；
   勿提交 VERSION_ROADMAP.txt。
8. 额外体验优化单独罗列，便于验收。
9. 欢迎页保持简洁；说明进 HelpView / StatsView。
10. 一个功能切片结束后建议用户同步检查点；用户要求 push 前必须跑 check-before-push.sh。

请先确认已读上述内容，然后等待我点名要讨论或要实现的项。
（建议：T1 基础策略引擎，无 UI。）
```

---

## 建议下一步（给维护者，不必贴进新窗）

| 优先级 | 项 | 为何现在做 | 步骤提纲 |
|--------|----|------------|----------|
| 1 | T1 基础策略表 | 公平闯关差异化；零 UI 风险 | `BasicStrategy.swift` 静态表 + 全表抽样单测 |
| 2 | T2 局末复盘 | 挂已有 SessionCoordinator | 可折叠对照；设置可关 |
| 3 | L5 + 提审标签 | 图标已有 | 截图、副标题、17+、隐私标签 |
| 4 | L2 分牌 | 须先产品锁 | 见 OPTIMIZATION_GUIDE L2 |
| 后置 | 广告 / 横屏 / C5 / F10 / A5 | 未齐 | 未点名不接 SDK |

**明确不做：** 闯关开道具；娱乐进闯关成就；独立练习分；未讨论就做 Even Money / 分牌；卖筹码。
