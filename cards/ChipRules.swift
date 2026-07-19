//
//  ChipRules.swift
//  cards
//
//  阶段 3（v1.7）+ 3.5（v1.7.1）：筹码与赔率常量；庄家资金池规则。
//

import Foundation

/// 桌面经济规则（纯常量，无状态）。
enum ChipRules {
    /// 玩家起始筹码 / 会话重置目标。
    static let startingBalance = 1000

    /// 庄家筹码池起始（庄家不另下注；玩家赢则从此池派彩）。
    static let dealerStartingBank = 2000

    /// 最小下注（相对起始 1000，小面额节奏过慢）。
    static let minimumBet = 100

    /// 下注页筹码面额：从 0 累加；单次累加后总注不得超过余额。
    static let betChipValues = [100, 200, 500]

    /// 下注页「余下全部」可追加进草稿的金额；0 表示不必显示 / 不可用。
    /// 仅在剩余额不是现有筹码档（100/200/500）时出现，避免与档位按钮重复。
    static func remainingDraftAddAmount(draftBet: Int, balance: Int) -> Int {
        guard draftBet >= 0, balance >= minimumBet else { return 0 }
        let remaining = balance - draftBet
        guard remaining > 0 else { return 0 }
        let newDraft = draftBet + remaining
        guard newDraft >= minimumBet, newDraft <= balance else { return 0 }
        // 恰好一档时用 +100 / +200 / +500 即可。
        if betChipValues.contains(remaining) { return 0 }
        return remaining
    }

    /// 破产回主页后欢迎页短提示。
    static let sessionClearedReturnHomeHint = "进度已清空，可重新开始。"

    /// 产品锁定：天然黑杰克开局见牌即结算，不进入玩家回合。
    /// 默认全下在发牌前完成，故天然 BJ 仍可吃到开局全下；见牌后再全下见道具规划。
    static let naturalBlackjackResolvesBeforePlayerTurn = true

    /// 默认练习：全下仅在开局下注页。对局中见牌后再全下留给道具（默认关闭）。
    /// - Note: 开启后接回 `ChipBank.goAllIn` + 牌桌「全下」键（见 `GameTableView`）。
    static let midHandAllInEnabled = false

    /// 开局下注页是否可「全下」（余额 ≥ 最小注）。
    static func canPreDealAllIn(balance: Int) -> Bool {
        balance >= minimumBet
    }

    /// 杀进程恢复后下注页提示（未结算注已退回，双方进度保留）。
    static let restoreAfterInterruptHint =
        "上次对局未完成，未结算注码已退回；双方筹码进度已保留。"

    /// 主动退出确认说明（与杀进程自动恢复相对）。
    static let abandonSessionConfirmDetail =
        "将清空双方筹码并返回主页（与杀进程后自动恢复进度不同）。当前进度不记入历史。"

    /// 欢迎页规则说明（短文案，适配小屏）。
    static var welcomeRulesSummary: String {
        "挑战庄家 \(dealerStartingBank)；打光或破产即结束。黑杰克见牌结算。"
    }

    /// 一副牌残局：剩余张数 ≤ 该值且本局不重洗时，开局「全下」以强调样式展示（强制全下）。
    /// 道具启用对局中全下时，同条件也可用于见牌后强调。
    static let forcedAllInRemainingCards = 15

    /// UserDefaults 键：玩家余额。
    static let balanceStorageKey = "chipBank.balance"

    /// UserDefaults 键：庄家筹码池。
    static let dealerBankStorageKey = "chipBank.dealerBank"

    /// UserDefaults 键：尚未结算的本局注码（用于杀进程 / 异常退出后退注）。
    static let activeBetStorageKey = "chipBank.activeBet"

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
    static let blackjackOddsLabel = "黑杰克赔率 3:2"

    /// 普通获胜赔率文案。
    static let evenMoneyOddsLabel = "普通胜负 1:1"

    /// 庄家筹码不足、只赔剩余时的说明。
    static let partialPayoutLabel = "庄家筹码不足，已赔付全部剩余"

    /// 黑杰克净赢：下注 × 3/2（整数向下取整）。本金另计退还。
    static func blackjackProfit(forBet bet: Int) -> Int {
        (bet * 3) / 2
    }

    /// 普通获胜净赢：1:1。
    static func evenMoneyProfit(forBet bet: Int) -> Int {
        bet
    }

    /// 某结局在庄家资金充足时应付的利润（不含退本；输/平为 0）。
    static func idealProfit(forBet bet: Int, outcome: RoundOutcome) -> Int {
        switch outcome {
        case .playerBlackjack:
            return blackjackProfit(forBet: bet)
        case .playerWin:
            return evenMoneyProfit(forBet: bet)
        case .playerLose, .push:
            return 0
        }
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
        case .playerBroke: return "你已破产"
        case .dealerBroke: return "庄家已破产"
        }
    }

    var detail: String {
        switch self {
        case .playerBroke:
            return "余额不足以继续下注，本局游戏结束。请返回主页后再开启新的一局。"
        case .dealerBroke:
            return "庄家筹码已全部赔出，本局游戏结束。请返回主页后再开启新的一局。"
        }
    }
}
