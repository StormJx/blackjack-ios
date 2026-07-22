//
//  Achievement.swift
//  cards
//
//  成就目录与判定。完整说明见仓库 docs/ACHIEVEMENTS.md（维护请同步更新该文档）。
//

import Foundation

/// 成就所属模式：挑战与练习进度 / 解锁相互隔离。
enum AchievementScope: String, CaseIterable, Identifiable, Sendable {
    case challenge
    case practice

    var id: String { rawValue }

    var tabTitle: String {
        switch self {
        case .challenge: return "闯关"
        case .practice: return "娱乐"
        }
    }
}

/// 一局结束后的手牌 / 胜负快照，供成就判定。
struct RoundSnapshot: Equatable, Sendable {
    let outcome: RoundOutcome
    let playerCardCount: Int
    let playerBest: Int
    let dealerBest: Int
    let playerBusted: Bool
    let dealerBusted: Bool
    let playerNaturalBlackjack: Bool
    let hitSurvivedFromOver17: Bool
    let hitSurvivedFromOver18: Bool
    let hitSurvivedFromOver19: Bool
    let hitFrom20To21: Bool
    /// 本局注码是否为全下（开局梭哈或对局中追加至全部余额）。
    let wasAllInBet: Bool

    init(
        outcome: RoundOutcome,
        playerCardCount: Int,
        playerBest: Int,
        dealerBest: Int,
        playerBusted: Bool,
        dealerBusted: Bool,
        playerNaturalBlackjack: Bool,
        hitSurvivedFromOver17: Bool = false,
        hitSurvivedFromOver18: Bool = false,
        hitSurvivedFromOver19: Bool = false,
        hitFrom20To21: Bool = false,
        wasAllInBet: Bool = false
    ) {
        self.outcome = outcome
        self.playerCardCount = playerCardCount
        self.playerBest = playerBest
        self.dealerBest = dealerBest
        self.playerBusted = playerBusted
        self.dealerBusted = dealerBusted
        self.playerNaturalBlackjack = playerNaturalBlackjack
        self.hitSurvivedFromOver17 = hitSurvivedFromOver17
        self.hitSurvivedFromOver18 = hitSurvivedFromOver18
        self.hitSurvivedFromOver19 = hitSurvivedFromOver19
        self.hitFrom20To21 = hitFrom20To21
        self.wasAllInBet = wasAllInBet
    }

    var playerWon: Bool {
        switch outcome {
        case .playerBlackjack, .playerWin: return true
        case .playerLose, .push: return false
        }
    }

    /// 仅两张牌非 BJ 获胜（初手制胜）。
    var isTwoCardNonBJWin: Bool {
        playerWon && playerCardCount == 2 && !playerNaturalBlackjack
    }
}

/// 单模式累计进度（挑战 / 练习各一份）。
struct ModeProgress: Equatable, Sendable {
    var rounds: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    var currentWinStreak: Int = 0
    var bestWinStreak: Int = 0
    var currentNoBustStreak: Int = 0
    var bestNoBustStreak: Int = 0
    var dealerBustWinCount: Int = 0
    var naturalBlackjackCount: Int = 0
    var fiveCardCharlieCount: Int = 0
    /// 全下（梭哈）获胜累计次数。
    var allInWinCount: Int = 0
}

/// 成就判定用完整输入。
struct AchievementProgressInput: Equatable, Sendable {
    var mode: ModeProgress
    /// 仅挑战：跨会话累计赢取筹码。
    var totalChipsWon: Int
    /// 仅挑战：打穿庄家池次数。
    var dealerBankClearCount: Int
    var unlocked: Set<AchievementID>
}

enum AchievementID: String, CaseIterable, Identifiable, Sendable {
    // MARK: 挑战 · 技巧一次性
    case fiveCardCharlie
    case speedBlackjack
    case comeback
    case exactTwentyOne
    case braveHitOver17
    case braveHitOver18
    case braveHitOver19
    case braveHit20To21
    case firstHandWin

    // MARK: 挑战 · 连胜阶梯
    case winStreak3
    case winStreak5
    case winStreak10

    // MARK: 挑战 · 稳健阶梯
    case noBust5
    case noBust10
    case noBust20

    // MARK: 挑战 · 胜场阶梯
    case wins10
    case wins25
    case wins50
    case wins100

    // MARK: 挑战 · 平局阶梯
    case push10
    case push20
    case push50

    // MARK: 挑战 · 庄家爆牌阶梯
    case dealerBust10
    case dealerBust25
    case dealerBust50

    // MARK: 挑战 · 黑杰克阶梯
    case naturalBJ5
    case naturalBJ15
    case naturalBJ30

    // MARK: 挑战 · 筹码 / 通关
    case chipsWon1000
    case chipsWon5000
    case chipsWon20000
    case dealerClear1
    case dealerClear5
    /// 全下获胜阶梯
    case allInWin5
    case allInWin15
    case allInWin30

    // MARK: 练习 · 连胜 / 胜场 / 平局 / 稳健
    case practiceWinStreak5
    case practiceWinStreak10
    case practiceWins20
    case practiceWins50
    case practiceWins100
    case practicePush10
    case practicePush20
    case practicePush50
    case practiceNoBust10
    case practiceNoBust20
    case practiceFiveCard
    case practiceNaturalBJ

    var id: String { rawValue }

    var scope: AchievementScope {
        switch self {
        case .practiceWinStreak5, .practiceWinStreak10,
             .practiceWins20, .practiceWins50, .practiceWins100,
             .practicePush10, .practicePush20, .practicePush50,
             .practiceNoBust10, .practiceNoBust20,
             .practiceFiveCard, .practiceNaturalBJ:
            return .practice
        default:
            return .challenge
        }
    }

    var title: String {
        switch self {
        case .fiveCardCharlie: return "五龙不过"
        case .speedBlackjack: return "极速黑杰克"
        case .comeback: return "绝地反击"
        case .exactTwentyOne: return "压线求生"
        case .braveHitOver17: return "险中求胜·十八"
        case .braveHitOver18: return "险中求胜·十九"
        case .braveHitOver19: return "险中求胜·二十"
        case .braveHit20To21: return "神之一手"
        case .firstHandWin: return "初手制胜"
        case .winStreak3: return "连胜起步"
        case .winStreak5: return "连胜节奏"
        case .winStreak10: return "连胜风暴"
        case .noBust5: return "稳健玩家"
        case .noBust10: return "稳如磐石"
        case .noBust20: return "钢铁神经"
        case .wins10: return "小有斩获"
        case .wins25: return "牌桌熟手"
        case .wins50: return "常胜将军"
        case .wins100: return "百战荣光"
        case .push10: return "平局入门"
        case .push20: return "平局达人"
        case .push50: return "平局大师"
        case .dealerBust10: return "爆牌收割·十"
        case .dealerBust25: return "爆牌收割·廿五"
        case .dealerBust50: return "爆牌收割·五十"
        case .naturalBJ5: return "黑杰克收藏·五"
        case .naturalBJ15: return "黑杰克收藏·十五"
        case .naturalBJ30: return "黑杰克收藏·三十"
        case .chipsWon1000: return "小赚一笔"
        case .chipsWon5000: return "盆满钵满"
        case .chipsWon20000: return "筹码大亨"
        case .dealerClear1: return "打穿庄家"
        case .dealerClear5: return "庄家克星"
        case .allInWin5: return "全下首胜"
        case .allInWin15: return "全下连捷"
        case .allInWin30: return "全下传说"
        case .practiceWinStreak5: return "练习连胜·五"
        case .practiceWinStreak10: return "练习连胜·十"
        case .practiceWins20: return "练习胜场·二十"
        case .practiceWins50: return "练习胜场·五十"
        case .practiceWins100: return "练习胜场·一百"
        case .practicePush10: return "练习平局·十"
        case .practicePush20: return "练习平局·二十"
        case .practicePush50: return "练习平局·五十"
        case .practiceNoBust10: return "练习稳健·十"
        case .practiceNoBust20: return "练习稳健·二十"
        case .practiceFiveCard: return "练习五龙"
        case .practiceNaturalBJ: return "练习极速 BJ"
        }
    }

    var detail: String {
        switch self {
        case .fiveCardCharlie: return "挑战中单局拿到 5 张牌且未爆牌"
        case .speedBlackjack: return "挑战中开局前两张即黑杰克"
        case .comeback: return "挑战中点数 20+ 仍获胜"
        case .exactTwentyOne: return "挑战中最终正好 21 且非黑杰克"
        case .braveHitOver17: return "挑战中点数 >17 要牌未爆并获胜"
        case .braveHitOver18: return "挑战中点数 >18 要牌未爆并获胜"
        case .braveHitOver19: return "挑战中 20 点要牌未爆并获胜"
        case .braveHit20To21: return "挑战中 20 点要牌正好 21 并获胜"
        case .firstHandWin: return "挑战中仅两张牌（非 BJ）停牌获胜"
        case .winStreak3: return "挑战模式连续获胜 3 局"
        case .winStreak5: return "挑战模式连续获胜 5 局"
        case .winStreak10: return "挑战模式连续获胜 10 局"
        case .noBust5: return "挑战模式连续 5 局未爆牌"
        case .noBust10: return "挑战模式连续 10 局未爆牌"
        case .noBust20: return "挑战模式连续 20 局未爆牌"
        case .wins10: return "挑战模式累计获胜 10 局"
        case .wins25: return "挑战模式累计获胜 25 局"
        case .wins50: return "挑战模式累计获胜 50 局"
        case .wins100: return "挑战模式累计获胜 100 局"
        case .push10: return "挑战模式累计平局 10 次"
        case .push20: return "挑战模式累计平局 20 次"
        case .push50: return "挑战模式累计平局 50 次"
        case .dealerBust10: return "挑战中庄家爆牌致胜累计 10 次"
        case .dealerBust25: return "挑战中庄家爆牌致胜累计 25 次"
        case .dealerBust50: return "挑战中庄家爆牌致胜累计 50 次"
        case .naturalBJ5: return "挑战中天然黑杰克累计 5 次"
        case .naturalBJ15: return "挑战中天然黑杰克累计 15 次"
        case .naturalBJ30: return "挑战中天然黑杰克累计 30 次"
        case .chipsWon1000: return "挑战模式累计赢取 1000 筹码"
        case .chipsWon5000: return "挑战模式累计赢取 5000 筹码"
        case .chipsWon20000: return "挑战模式累计赢取 20000 筹码"
        case .dealerClear1: return "打穿庄家资金池 1 次"
        case .dealerClear5: return "打穿庄家资金池 5 次"
        case .allInWin5: return "挑战中全下获胜累计 5 次"
        case .allInWin15: return "挑战中全下获胜累计 15 次"
        case .allInWin30: return "挑战中全下获胜累计 30 次"
        case .practiceWinStreak5: return "娱乐模式连续获胜 5 局"
        case .practiceWinStreak10: return "娱乐模式连续获胜 10 局"
        case .practiceWins20: return "娱乐模式累计获胜 20 局"
        case .practiceWins50: return "娱乐模式累计获胜 50 局"
        case .practiceWins100: return "娱乐模式累计获胜 100 局"
        case .practicePush10: return "娱乐模式累计平局 10 次"
        case .practicePush20: return "娱乐模式累计平局 20 次"
        case .practicePush50: return "娱乐模式累计平局 50 次"
        case .practiceNoBust10: return "娱乐模式连续 10 局未爆牌"
        case .practiceNoBust20: return "娱乐模式连续 20 局未爆牌"
        case .practiceFiveCard: return "娱乐模式单局 5 张未爆"
        case .practiceNaturalBJ: return "娱乐模式开局天然黑杰克"
        }
    }

    var progressTarget: Int {
        switch self {
        case .fiveCardCharlie, .speedBlackjack, .comeback, .exactTwentyOne,
             .braveHitOver17, .braveHitOver18, .braveHitOver19, .braveHit20To21,
             .firstHandWin, .dealerClear1, .practiceFiveCard, .practiceNaturalBJ:
            return 1
        case .winStreak3:
            return 3
        case .winStreak5, .practiceWinStreak5, .noBust5, .naturalBJ5, .dealerClear5:
            return 5
        case .winStreak10, .practiceWinStreak10, .noBust10, .practiceNoBust10,
             .wins10, .push10, .dealerBust10, .practicePush10:
            return 10
        case .naturalBJ15:
            return 15
        case .noBust20, .practiceNoBust20, .push20, .practiceWins20, .practicePush20:
            return 20
        case .wins25, .dealerBust25:
            return 25
        case .naturalBJ30:
            return 30
        case .wins50, .push50, .dealerBust50, .practiceWins50, .practicePush50:
            return 50
        case .wins100, .practiceWins100:
            return 100
        case .allInWin5:
            return 5
        case .allInWin15:
            return 15
        case .allInWin30:
            return 30
        case .chipsWon1000:
            return 1000
        case .chipsWon5000:
            return 5000
        case .chipsWon20000:
            return 20000
        }
    }

    static func ids(in scope: AchievementScope) -> [AchievementID] {
        allCases.filter { $0.scope == scope }
    }
}

enum AchievementEvaluator {
    /// 按本局快照更新对应模式进度，并仅解锁该 scope 下的成就。
    static func evaluate(
        snapshot: RoundSnapshot,
        scope: AchievementScope,
        progress: inout AchievementProgressInput
    ) -> [AchievementID] {
        var newly: [AchievementID] = []

        func unlock(_ id: AchievementID) {
            guard id.scope == scope else { return }
            guard !progress.unlocked.contains(id) else { return }
            progress.unlocked.insert(id)
            newly.append(id)
        }

        // —— 更新模式计数 ——
        progress.mode.rounds += 1
        switch snapshot.outcome {
        case .playerBlackjack, .playerWin:
            progress.mode.wins += 1
            progress.mode.currentWinStreak += 1
            progress.mode.bestWinStreak = max(progress.mode.bestWinStreak, progress.mode.currentWinStreak)
        case .playerLose:
            progress.mode.losses += 1
            progress.mode.currentWinStreak = 0
        case .push:
            progress.mode.pushes += 1
            progress.mode.currentWinStreak = 0
        }

        if snapshot.playerBusted {
            progress.mode.currentNoBustStreak = 0
        } else {
            progress.mode.currentNoBustStreak += 1
            progress.mode.bestNoBustStreak = max(
                progress.mode.bestNoBustStreak,
                progress.mode.currentNoBustStreak
            )
        }

        if snapshot.playerWon && snapshot.dealerBusted {
            progress.mode.dealerBustWinCount += 1
        }
        if snapshot.playerNaturalBlackjack {
            progress.mode.naturalBlackjackCount += 1
        }
        if snapshot.playerCardCount >= 5 && !snapshot.playerBusted {
            progress.mode.fiveCardCharlieCount += 1
        }
        if snapshot.playerWon && snapshot.wasAllInBet {
            progress.mode.allInWinCount += 1
        }

        let m = progress.mode

        switch scope {
        case .challenge:
            // 技巧一次性
            if snapshot.playerCardCount >= 5 && !snapshot.playerBusted {
                unlock(.fiveCardCharlie)
            }
            if snapshot.playerNaturalBlackjack { unlock(.speedBlackjack) }
            if snapshot.playerWon && snapshot.playerBest >= 20 { unlock(.comeback) }
            if snapshot.playerBest == 21 && !snapshot.playerNaturalBlackjack && !snapshot.playerBusted {
                unlock(.exactTwentyOne)
            }
            if snapshot.playerWon {
                if snapshot.hitSurvivedFromOver17 { unlock(.braveHitOver17) }
                if snapshot.hitSurvivedFromOver18 { unlock(.braveHitOver18) }
                if snapshot.hitSurvivedFromOver19 { unlock(.braveHitOver19) }
                if snapshot.hitFrom20To21 { unlock(.braveHit20To21) }
            }
            if snapshot.isTwoCardNonBJWin { unlock(.firstHandWin) }

            // 连胜 / 稳健
            if m.bestWinStreak >= 3 { unlock(.winStreak3) }
            if m.bestWinStreak >= 5 { unlock(.winStreak5) }
            if m.bestWinStreak >= 10 { unlock(.winStreak10) }
            if m.bestNoBustStreak >= 5 { unlock(.noBust5) }
            if m.bestNoBustStreak >= 10 { unlock(.noBust10) }
            if m.bestNoBustStreak >= 20 { unlock(.noBust20) }

            // 胜场 / 平局 / 爆牌 / BJ
            if m.wins >= 10 { unlock(.wins10) }
            if m.wins >= 25 { unlock(.wins25) }
            if m.wins >= 50 { unlock(.wins50) }
            if m.wins >= 100 { unlock(.wins100) }
            if m.pushes >= 10 { unlock(.push10) }
            if m.pushes >= 20 { unlock(.push20) }
            if m.pushes >= 50 { unlock(.push50) }
            if m.dealerBustWinCount >= 10 { unlock(.dealerBust10) }
            if m.dealerBustWinCount >= 25 { unlock(.dealerBust25) }
            if m.dealerBustWinCount >= 50 { unlock(.dealerBust50) }
            if m.naturalBlackjackCount >= 5 { unlock(.naturalBJ5) }
            if m.naturalBlackjackCount >= 15 { unlock(.naturalBJ15) }
            if m.naturalBlackjackCount >= 30 { unlock(.naturalBJ30) }

            // 筹码（由外部累加后传入）
            if progress.totalChipsWon >= 1000 { unlock(.chipsWon1000) }
            if progress.totalChipsWon >= 5000 { unlock(.chipsWon5000) }
            if progress.totalChipsWon >= 20000 { unlock(.chipsWon20000) }
            if progress.dealerBankClearCount >= 1 { unlock(.dealerClear1) }
            if progress.dealerBankClearCount >= 5 { unlock(.dealerClear5) }
            if m.allInWinCount >= 5 { unlock(.allInWin5) }
            if m.allInWinCount >= 15 { unlock(.allInWin15) }
            if m.allInWinCount >= 30 { unlock(.allInWin30) }

        case .practice:
            if m.bestWinStreak >= 5 { unlock(.practiceWinStreak5) }
            if m.bestWinStreak >= 10 { unlock(.practiceWinStreak10) }
            if m.wins >= 20 { unlock(.practiceWins20) }
            if m.wins >= 50 { unlock(.practiceWins50) }
            if m.wins >= 100 { unlock(.practiceWins100) }
            if m.pushes >= 10 { unlock(.practicePush10) }
            if m.pushes >= 20 { unlock(.practicePush20) }
            if m.pushes >= 50 { unlock(.practicePush50) }
            if m.bestNoBustStreak >= 10 { unlock(.practiceNoBust10) }
            if m.bestNoBustStreak >= 20 { unlock(.practiceNoBust20) }
            if snapshot.playerCardCount >= 5 && !snapshot.playerBusted {
                unlock(.practiceFiveCard)
            }
            if snapshot.playerNaturalBlackjack {
                unlock(.practiceNaturalBJ)
            }
        }

        return newly
    }

    static func displayedProgress(
        for id: AchievementID,
        progress: AchievementProgressInput
    ) -> Int {
        let m = progress.mode
        let target = id.progressTarget
        let raw: Int
        switch id {
        case .fiveCardCharlie, .speedBlackjack, .comeback, .exactTwentyOne,
             .braveHitOver17, .braveHitOver18, .braveHitOver19, .braveHit20To21,
             .firstHandWin, .practiceFiveCard, .practiceNaturalBJ:
            return progress.unlocked.contains(id) ? 1 : 0
        case .winStreak3, .winStreak5, .winStreak10,
             .practiceWinStreak5, .practiceWinStreak10:
            raw = m.bestWinStreak
        case .noBust5, .noBust10, .noBust20, .practiceNoBust10, .practiceNoBust20:
            raw = m.bestNoBustStreak
        case .wins10, .wins25, .wins50, .wins100,
             .practiceWins20, .practiceWins50, .practiceWins100:
            raw = m.wins
        case .push10, .push20, .push50,
             .practicePush10, .practicePush20, .practicePush50:
            raw = m.pushes
        case .dealerBust10, .dealerBust25, .dealerBust50:
            raw = m.dealerBustWinCount
        case .naturalBJ5, .naturalBJ15, .naturalBJ30:
            raw = m.naturalBlackjackCount
        case .chipsWon1000, .chipsWon5000, .chipsWon20000:
            raw = progress.totalChipsWon
        case .dealerClear1, .dealerClear5:
            raw = progress.dealerBankClearCount
        case .allInWin5, .allInWin15, .allInWin30:
            raw = m.allInWinCount
        }
        return min(raw, target)
    }
}
