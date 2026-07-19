//
//  RoundSettlement.swift
//  cards
//
//  阶段 3 / 3.5：纯函数结算。下注已从玩家余额扣出后调用；含庄家池不足额赔付。
//

import Foundation

/// 一局筹码结算结果（可供 UI 与单测直接断言）。
struct SettlementResult: Equatable, Sendable {
    /// 本局下注额。
    let betAmount: Int
    /// 胜负类别。
    let outcome: RoundOutcome
    /// 相对「扣注后余额」的净变动（赢为正、输为负、平为 0）。
    /// 不足额赔付时，正值可能小于足额派彩。
    let netChange: Int
    /// 结算后打回玩家账户的筹码（含退本与实际派彩；输则为 0）。
    let amountReturned: Int
    /// 结算完成后的玩家余额。
    let balanceAfter: Int
    /// 结算完成后的庄家筹码池。
    let dealerBankAfter: Int
    /// 足额时应得利润（不含本金）；用于判断是否部分赔付。
    let idealProfit: Int
    /// 实际从庄家池支付的利润（输/平时为 0）。
    let profitPaid: Int

    /// 赢牌但庄家池不足以支付足额利润。
    var wasPartialPayout: Bool {
        switch outcome {
        case .playerBlackjack, .playerWin:
            return profitPaid < idealProfit
        case .playerLose, .push:
            return false
        }
    }

    /// 局末弹窗「本局盈亏」文案。
    var netChangeLabel: String {
        if netChange > 0 { return "+\(netChange)" }
        if netChange < 0 { return "\(netChange)" }
        return "0（平局退注）"
    }

    /// 赔率说明：黑杰克写明 3:2；普通胜写明 1:1；其余为 nil。
    var oddsLabel: String? {
        switch outcome {
        case .playerBlackjack:
            return ChipRules.blackjackOddsLabel
        case .playerWin:
            return ChipRules.evenMoneyOddsLabel
        case .playerLose, .push:
            return nil
        }
    }

    /// 不足额赔付时的补充说明。
    var partialPayoutLabel: String? {
        wasPartialPayout ? ChipRules.partialPayoutLabel : nil
    }
}

/// 独立结算模块：只做筹码算术，不碰发牌 / 动画状态机。
enum RoundSettlement {
    /// - Parameters:
    ///   - balanceAfterBet: 已扣除下注后的玩家余额。
    ///   - betAmount: 本局下注（须 > 0）。
    ///   - dealerBank: 结算前庄家筹码池（须 ≥ 0）。
    ///   - outcome: 对局结果。
    /// - Returns: 结算明细；赢时利润 = min(应付利润, dealerBank)。
    static func settle(
        balanceAfterBet: Int,
        betAmount: Int,
        dealerBank: Int,
        outcome: RoundOutcome
    ) -> SettlementResult {
        precondition(betAmount > 0, "betAmount must be positive")
        precondition(dealerBank >= 0, "dealerBank must be non-negative")

        let ideal = ChipRules.idealProfit(forBet: betAmount, outcome: outcome)
        let profitPaid: Int
        let amountReturned: Int
        let dealerBankAfter: Int
        let netChange: Int

        switch outcome {
        case .playerBlackjack, .playerWin:
            // 有多少赔多少：利润不超过庄家池；本金始终退回。
            profitPaid = min(ideal, dealerBank)
            amountReturned = betAmount + profitPaid
            dealerBankAfter = dealerBank - profitPaid
            netChange = profitPaid
        case .playerLose:
            profitPaid = 0
            amountReturned = 0
            dealerBankAfter = dealerBank + betAmount
            netChange = -betAmount
        case .push:
            profitPaid = 0
            amountReturned = betAmount
            dealerBankAfter = dealerBank
            netChange = 0
        }

        return SettlementResult(
            betAmount: betAmount,
            outcome: outcome,
            netChange: netChange,
            amountReturned: amountReturned,
            balanceAfter: balanceAfterBet + amountReturned,
            dealerBankAfter: dealerBankAfter,
            idealProfit: ideal,
            profitPaid: profitPaid
        )
    }
}
