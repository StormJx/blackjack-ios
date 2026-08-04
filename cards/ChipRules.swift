//
//  ChipRules.swift
//  cards
//
//  阶段 3（v1.7）+ 3.5（v1.7.1）：筹码与赔率常量；庄家资金池规则。
//

import Foundation

/// 桌面经济规则（纯常量，无状态）。
enum ChipRules {
    /// 玩家起始筹码 / 会话重置目标（闯关第 1 关 / 娱乐默认）。
    static let startingBalance = 1000

    /// 庄家筹码池起始（闯关第 1 关 / 娱乐默认）。
    static let dealerStartingBank = 2000

    /// 最小下注（来自当前生效桌限；默认标准档 100）。
    static var minimumBet: Int { ActiveTableLimits.minimumBet }

    /// 下注页筹码面额：三档单选（点选即覆盖，不可累加）。
    static var betChipValues: [Int] { ActiveTableLimits.betChipValues }

    /// F1：开局「全下」解锁局数默认值（设置可改；进程内生效值见 `ActivePreDealAllInUnlock`）。
    static let defaultPreDealAllInUnlockCompletedRounds = 5

    /// 设置页可配范围（含 0 = 开局即可全下）。
    static let preDealAllInUnlockRoundsRange = 0...10

    static func clampPreDealAllInUnlockRounds(_ value: Int) -> Int {
        min(
            max(value, preDealAllInUnlockRoundsRange.lowerBound),
            preDealAllInUnlockRoundsRange.upperBound
        )
    }

    /// 当前会话生效的解锁局数（新开局时由设置同步）。
    static var preDealAllInUnlockCompletedRounds: Int {
        ActivePreDealAllInUnlock.requiredRounds
    }

    /// 是否可选中该筹码档作为本局唯一注码。
    static func canSelectBetChip(_ value: Int, balance: Int) -> Bool {
        betChipValues.contains(value) && value >= minimumBet && value <= balance
    }

    /// 开局下注页是否满足「全下」基础条件（余额 ≥ 最小注）。
    static func canPreDealAllIn(balance: Int) -> Bool {
        balance >= minimumBet
    }

    /// 开局全下是否可用：局数解锁 + 尚未点选筹码档（避免与红色全下误触）。
    /// - Note: `draftBet == 0` 表示未选档；已选档时全下灰显，需先「清空」再全下。
    static func isPreDealAllInEnabled(
        balance: Int,
        sessionRoundsCompleted: Int,
        draftBet: Int,
        unlockRounds: Int = ActivePreDealAllInUnlock.requiredRounds
    ) -> Bool {
        canPreDealAllIn(balance: balance)
            && sessionRoundsCompleted >= unlockRounds
            && draftBet == 0
    }

    /// 全下未解锁时的提示文案。
    static func preDealAllInLockHint(
        sessionRoundsCompleted: Int,
        unlockRounds: Int = ActivePreDealAllInUnlock.requiredRounds
    ) -> String? {
        guard sessionRoundsCompleted < unlockRounds else { return nil }
        let left = unlockRounds - sessionRoundsCompleted
        return L10n.format("chips.preDealAllInLockFormat", left)
    }

    /// 破产回主页后欢迎页短提示。
    static var sessionClearedReturnHomeHint: String { L10n.t("chips.sessionClearedHint") }

    /// 产品锁定：天然黑杰克开局见牌即结算，不进入玩家回合。
    /// 默认全下在发牌前完成，故天然 BJ 仍可吃到开局全下；对局中见牌后再全下由 `PropStore.owns(.midHandAllIn)` 门控。
    static let naturalBlackjackResolvesBeforePlayerTurn = true

    /// 杀进程恢复后下注页提示（未结算注已退回；筹码与全下解锁局数保留）。
    static var restoreAfterInterruptHint: String { L10n.t("chips.restoreAfterInterrupt") }

    /// 主动退出确认说明（与杀进程自动恢复相对）。
    static var abandonSessionConfirmDetail: String { L10n.t("chips.abandonConfirmDetail") }

    /// 闯关欢迎页规则说明。
    static var challengeWelcomeSummary: String {
        let need = preDealAllInUnlockCompletedRounds
        let allInNote = need == 0
            ? L10n.t("chips.challengeWelcome.allInZero")
            : L10n.format("chips.challengeWelcome.allInRoundsFormat", need)
        return L10n.format("chips.challengeWelcomeFormat", allInNote)
    }

    /// 兼容旧调用。
    static var welcomeRulesSummary: String { challengeWelcomeSummary }

    /// 一副牌残局：剩余张数 ≤ 该值且本局不重洗时，开局「全下」以强调样式展示（强制全下）。
    /// 道具启用对局中全下时，同条件也可用于见牌后强调。
    static let forcedAllInRemainingCards = 15

    /// UserDefaults 键：玩家余额。
    static let balanceStorageKey = "chipBank.balance"

    /// UserDefaults 键：庄家筹码池。
    static let dealerBankStorageKey = "chipBank.dealerBank"

    /// UserDefaults 键：尚未结算的本局注码（用于杀进程 / 异常退出后退注）。
    static let activeBetStorageKey = "chipBank.activeBet"

    /// UserDefaults 键：本会话已完成局数（开局全下解锁；与筹码同 suite 持久化）。
    static let sessionRoundsStorageKey = "chipBank.sessionRoundsCompleted"

    /// 一副牌残局「强制全下」强调样式是否应出现（开局下注页；道具开启后亦可用于对局中）。
    /// - Note: `willReshuffle` 为 true 时本局会先重洗，剩余张数不再是开局牌况，故不展示。
    static func canUseForcedAllIn(
        isSingleDeck: Bool,
        remainingCards: Int,
        willReshuffle: Bool
    ) -> Bool {
        isSingleDeck
            && remainingCards > 0
            && remainingCards <= forcedAllInRemainingCards
            && !willReshuffle
    }

    /// 黑杰克赔率文案（结算 UI 与结果区共用）。
    static var blackjackOddsLabel: String { L10n.t("chips.odds.blackjack") }

    /// 普通获胜赔率文案。
    static var evenMoneyOddsLabel: String { L10n.t("chips.odds.normal") }

    /// 投降结算说明。
    static var surrenderOddsLabel: String { L10n.t("chips.odds.surrender") }

    /// P6+ 保险：赔率说明（庄家黑杰克时保险 2:1）。
    static var insuranceOddsLabel: String { L10n.t("chips.odds.insurance") }

    /// P6+ 保险：未中说明（庄家非黑杰克）。
    static var insuranceLostLabel: String { L10n.t("chips.odds.insuranceMiss") }

    /// 庄家筹码不足、只赔剩余时的说明。
    static var partialPayoutLabel: String { L10n.t("chips.partialPayout") }

    /// UserDefaults 键：尚未结算的保险侧注。
    static let activeInsuranceStorageKey = "chipBank.activeInsurance"

    /// 保险注码：主注一半（向下取整）。
    static func insuranceBetAmount(forMainBet bet: Int) -> Int {
        max(0, bet / 2)
    }

    /// 保险足额利润（2:1，不含退还保险本金）。
    static func insuranceProfit(forInsuranceBet bet: Int) -> Int {
        bet * 2
    }

    /// 黑杰克净赢：下注 × 3/2（整数向下取整）。本金另计退还。
    static func blackjackProfit(forBet bet: Int) -> Int {
        (bet * 3) / 2
    }

    /// 普通获胜净赢：1:1。
    static func evenMoneyProfit(forBet bet: Int) -> Int {
        bet
    }

    /// 某结局在庄家资金充足时应付的利润（不含退本；输/平/投降为 0）。
    static func idealProfit(forBet bet: Int, outcome: RoundOutcome) -> Int {
        switch outcome {
        case .playerBlackjack:
            return blackjackProfit(forBet: bet)
        case .playerWin:
            return evenMoneyProfit(forBet: bet)
        case .playerLose, .push, .playerSurrender:
            return 0
        }
    }
}

/// 进程内当前生效的开局全下解锁局数；由欢迎页 / 开新会话时同步。
enum ActivePreDealAllInUnlock {
    static var requiredRounds: Int = ChipRules.defaultPreDealAllInUnlockCompletedRounds

    static func apply(_ rounds: Int) {
        requiredRounds = ChipRules.clampPreDealAllInUnlockRounds(rounds)
    }
}

/// 练习会话因任一方筹码耗尽而结束时的原因。
enum SessionEndReason: Equatable, Sendable {
    /// 玩家余额不足以最小下注。
    case playerBroke
    /// 庄家筹码池已掏空。
    case dealerBroke

    var title: String {
        switch self {
        case .playerBroke: return L10n.t("sessionEnd.playerBroke")
        case .dealerBroke: return L10n.t("sessionEnd.dealerBroke")
        }
    }

    var detail: String {
        switch self {
        case .playerBroke: return L10n.t("sessionEnd.playerBroke.detail")
        case .dealerBroke: return L10n.t("sessionEnd.dealerBroke.detail")
        }
    }
}
