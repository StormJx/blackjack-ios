# 工程评审 backlog（须点名再做）

> 来源：2026-07-27 工程 / UX / 质量评审。  
> 会话检查点：`docs/SESSION_CHECKPOINT.md` · P8 细则：`docs/P8_ORIENTATION_AND_A11Y.md`  
> **未点名不实现**；本文件只作排期与验收清单。

---

## 已完成（本评审批次内）

| 项 | 说明 |
|----|------|
| 换庄家牌堆边界 | `returnCardToShoe` 回退 `dealtCount`；非空鞋禁止立即原样抽回 |
| F2 战绩进度 | `StatsView` 展示闯关关 / 娱乐阶、起始筹码、下一门槛、娱乐累计 |

---

## P0 / 高优先级（下一刀优先）

### Q1 — 杀进程恢复与「本会话全下解锁局数」

- **现状**：`ChipBank` 会恢复双方筹码；`sessionRoundsCompleted` 仅为 `GameSessionView` 的 `@State`，杀进程后归零。
- **冲突**：`ChipRules.restoreAfterInterruptHint` 写「进度已保留」，但全下解锁局数未保留。
- **方案（二选一，点名时锁定）**：
  1. 与 `ChipBank` 同 suite 持久化 `sessionRoundsCompleted`；或
  2. 文案明确「全下解锁计数不保留」，并保持现状。
- **验收**：中断恢复后行为与文案一致；补 1–2 条单测。

### P8 无障碍第一切片（横屏后置）

详见 `docs/P8_ORIENTATION_AND_A11Y.md`「第一切片」。摘要：

1. 下注 / 局末 overlay 可滚动，主按钮（确认并发牌 / 继续）大字体下仍可达。
2. VoiceOver：点数、余额、注码、结果、要牌/停牌、道具（含具体禁用原因）。
3. 动态字体抽查欢迎页与面板；固定 `size:` 改为可缩放或设上限。
4. 洗牌 overlay 尊重 `accessibilityReduceMotion`。
5. 设置页去掉面向开发者的 `Sounds/` 技术文案（可选同切片）。

### Q2 — 进入 P6 前改善状态机可测性

1. `BlackjackGame` 注入可控牌堆 / RNG / 延迟时钟 / 反馈接口（局部改造，勿全面 MVVM）。
2. 桌限与全下门槛改为会话级不可变 `SessionConfiguration`，逐步替代 `ActiveTableLimits` / `ActivePreDealAllInUnlock` 进程全局。
3. 补确定性单测：天然 BJ、hit/stand/爆牌、庄家软 17（默认停 / 道具要）、牌尽 fallback。
4. 可选：抽出 `SessionProgressCoordinator`，降低 `handleRoundFinished` 编排风险。
5. 退出会话时 `cancelPendingWork()`（peek / hint / pulse Task）。

---

## P1 / 体验与产品（可后置）

| 编号 | 内容 | 备注 |
|------|------|------|
| UX1 | 欢迎页模式副文案 | 已有 `PlayStyle.welcomeSubtitle`，未接线；保持主页简洁时可只加 1 行 |
| UX2 | 局内全下二次确认 | 可设置关闭；防误触 |
| UX3 | 成就解锁队列 / 卡片 | 替代超长 ` · ` 拼接 toast |
| UX4 | 成就页道具区仅娱乐 tab | 闯关 tab 减少噪音；跨模式解锁加「去闯关解锁」标签 |
| UX5 | 接线 `FastSessionStats` 或删除死分支 | `SessionRoundEndPanel` 现传 `nil` |
| UX6 | 窥视倒计时 UI / 道具首次引导 | discoverability |
| UX7 | 局末可先看牌面再下注 | overlay 可暂时收起 |
| UX8 | 成就命名「练习」→「娱乐」 | 文案一致性 |
| UX9 | 设置变更「对局中不生效」全局提示 | 减少困惑 |

---

## P2 / 功能大项（须先锁产品）

| 编号 | 内容 | 备注 |
|------|------|------|
| P6 | **先「加倍」单切片** | 仍单手模型；锁：仅前两张？不足额赔付？是否计全下成就？ |
| P6+ | 投降 → 保险 → 分牌 | 分牌最后做（多手状态机） |
| C5 | 对道具战 | 庄家 AI 时机与平衡；欢迎页第三入口 |
| F10 | 正片录音 wav | 基名不变，替换 `Sounds/` |
| 阶梯数值 | 娱乐表试玩后调 | 先采样再改 |

---

## 明确不做 / 不急

- 闯关启用玩法道具；娱乐计入闯关成就；默认模式独立练习分
- 全面重写 MVVM / 多模块；引入 SwiftData；优化 `Deck.removeFirst`
- 继续堆卡背 / 成就数量（先可发现性）
- 追求 100% 测试覆盖或重量级 UI 快照
- 账号 / 云同步 / 排行榜

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-27 | 初版：汇总架构 / UX / 质量评审；F2 与牌堆边界已落地 |
