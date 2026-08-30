# App Store 提审填写稿（L5）

> 配合：应用内 `PrivacyView`、`PrivacyInfo.xcprivacy`、静态页 `docs/privacy.html`（GitHub Pages 步骤见 `docs/GITHUB_PAGES.md`）。  
> 截图：`store/screenshots/`（由 `scripts/capture-store-screenshots.sh` 生成）。  
> **本文件不能代替在 App Store Connect 里点选；按表填写即可。**

**工程：** `MARKETING_VERSION = 2.0` / `CURRENT_PROJECT_VERSION = 2`  
**主屏幕名：** 中文「二十一点」/ 英文 Blackjack（`CFBundleDisplayName`）  
**图标：** 绯红缎带牌背 45° 扇形（已入库）

---

## 1. 商店文案

字符限制按 App Store Connect：名称 30、副标题 30、宣传文本 170、关键词 100、描述 4000。

### 简体中文（zh-Hans）

| 字段 | 文案 |
|------|------|
| 名称 | 二十一点 |
| 副标题 | 公平闯关练习 |
| 宣传文本 | 干净的二十一点练习：公平闯关升关，娱乐模式另有道具。模拟筹码，不是真钱赌博。 |
| 关键词 | Blackjack,练习,闯关,娱乐,扑克,筹码,加倍,投降,保险,赌场,卡牌 |
| 类别 | 游戏 → 卡牌；可选第二类别：游戏 → 赌场 |

**描述：**

二十一点是一款以公平闯关为主的练习应用。用模拟筹码挑战庄家资金池，打穿或累计获胜即可升关；娱乐模式独立进阶，已解锁的玩法道具只在该模式生效。

规则为简化赌场二十一点：庄家小于 17 要牌、17 及以上停牌（软 17 同停）。开局两张可加倍或投降；庄家明 A 可买保险。本版暂不分牌。筹码仅供练习，不能兑换现金，也不出售筹码。

可在设置中选择跟随系统、中文或 English。战绩、成就与进度只存在本机。当前版本没有广告 SDK，对局进行中不会插广告。

适合想按规则把二十一点打明白的玩家，而不是社交赌场。

### English (en)

| Field | Copy |
|-------|------|
| Name | Blackjack |
| Subtitle | Fair Challenge Practice |
| Promotional Text | A clean blackjack practice app: fair Challenge stages, optional Entertainment props. Simulated chips only — not real-money gambling. |
| Keywords | twenty-one,practice,challenge,cards,casino,chips,hit,stand,double,surrender,insurance |
| Category | Games → Card; optional secondary: Games → Casino |

**Description:**

Blackjack is a fair-challenge-first practice app. Play with simulated chips against a dealer bank; clear the bank or accumulate winnings to advance stages. Entertainment mode has its own ladder, and gameplay props stay in that mode only.

Rules are simplified casino blackjack: the dealer hits below 17 and stands on 17 or more, including soft 17. On your first two cards you may double or surrender; insurance is offered when the dealer shows an Ace. This version does not include splitting. Chips are for practice only — they cannot be cashed out, and the app does not sell chips.

Choose Follow System, Chinese, or English in Settings. Stats, achievements, and progress stay on this device. This version has no ad SDK and will not insert ads during a hand.

Built for learning the rules cleanly, not for a social-casino loop.

### 版本「新功能」（2.0）

- 中文：公平闯关定位；设置可切换中文 / English；隐私说明；界面英文本地化。
- English: Fair-challenge positioning; in-app language (Chinese / English); privacy note; full English UI.

### 文案约束（避免拒审 / 误导）

- 不写「赢钱」「提现」「真钱」「策略教练 / basic strategy trainer」（T1 仅引擎，无教学 UI）。
- 必须写明：模拟筹码、非真实货币赌博。
- 不承诺上架后有广告或去广告内购（尚未接线）。

---

## 2. 截图规格（2026）

App Store Connect 当前**必传**的是 **6.9 英寸** iPhone 一组（1–10 张）。该槽接受 `1320×2868`（iPhone 16 Pro Max）、`1290×2796` 或 `1260×2736`。上传后会缩放填到更小机型。

检查点里的「6.7″ / 6.1″」已并入 6.9″ 槽：6.7″ 不再单独必传；6.1″ 可选。本仓库默认产出 **6.9″（1320×2868）中文 + 英文**。

| 文件 | 画面 |
|------|------|
| `01-welcome` | 欢迎页：闯关 / 娱乐入口 |
| `02-bet` | 闯关下注 |
| `03-table` | 发牌后的牌桌 |
| `04-help` | 帮助说明（定位与规则） |
| `05-settings` | 设置（语言等） |

路径：`store/screenshots/iphone-69/{zh-Hans,en}/`。重拍：`./scripts/capture-store-screenshots.sh`（一次一个模拟器）。

本 App 仅 iPhone、仅竖屏；**不必**传 iPad / 横屏。预览视频本刀不做。

---

## 3. 年龄分级（填 17+）

App Store Connect → App 信息 → 年龄分级问卷。含**模拟赌博**须报 17+。

| 问卷项（英文大意） | 选 |
|--------------------|----|
| Cartoon / Fantasy / Realistic Violence | None |
| Sexual Content / Nudity | None |
| Profanity / Crude Humor | None |
| Alcohol / Tobacco / Drugs | None |
| Horror / Fear Themes | None |
| Medical / Treatment Information | None |
| Unrestricted Web Access | No |
| Gambling（真钱） | **No** |
| **Simulated Gambling（模拟赌博）** | **Yes**，且为应用核心（Frequent） |
| Contests | No |
| 用户能否用真钱买数字商品 | **No**（本版无 IAP） |
| 年龄门控 / 家长控制 | 无额外门控；依赖商店 17+ |

结果应为 **17+**。中国大陆区对模拟赌博审核极严，**首发建议港台 / 东南亚 / 欧美，大陆区另评估**。

---

## 4. App 隐私标签

与 `PrivacyInfo.xcprivacy`、应用内隐私说明一致。**接广告或统计后必须改。**

| 项 | 填 |
|----|----|
| 是否收集数据 | **不，我们不收集此 App 中的数据**（Data Not Collected） |
| 用于追踪的数据 | 无（`NSPrivacyTracking = false`） |
| 第三方 / 广告 / 分析 SDK | 无 |
| 使用的 API 声明 | UserDefaults，原因 **CA92.1**（仅本机进度与设置） |

隐私政策 URL：按 `docs/GITHUB_PAGES.md` 发布后填  
`https://stormjx.github.io/blackjack-ios/privacy.html`。商店**需要**可公开访问的政策页；仅应用内说明不够。

联系邮箱、技术支持 URL：在 Connect 自行填（可用仓库 Issues 页作临支持）。

---

## 5. 提审前核对

- [ ] Connect 名称 / 副标题 / 描述 / 关键词已按上表粘贴（中英各一套）
- [ ] 6.9″ 截图已上传（建议中英各 5 张）
- [ ] 年龄分级问卷已提交，显示 17+
- [ ] 隐私标签为「不收集数据」
- [ ] 隐私政策 URL 可打开，内容与 `docs/privacy.html` 一致
- [ ] 出口合规 / 内容版权等其余问卷按实填（本 App 无加密定制、无第三方内容）
- [ ] 定价：免费；销售范围避开尚未评估的大陆区（若采用该策略）

广告 SDK、ATT、去广告 IAP **本刀不接**；若以后接 M1，须同步改隐私标签、政策页与年龄/追踪说明。
