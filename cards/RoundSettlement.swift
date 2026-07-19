//
//  RoundSettlement.swift
//  cards
//
//  阶段 3（v1.7）：纯函数结算。下注已从余额扣出后调用；不依赖 BlackjackGame。
//

import Foundation

/// 一局筹码结算结果（可供 UI 与单测直接断言）。
struct SettlementResult: Equatable, Sendable {
    /// 本局下注额。
    let betAmount: Int
    /// 胜负类别。
    let outcome: RoundOutcome
    /// 相对「扣注后余额」的净变动（赢为正、输为负、平为 0）。
    /// 即：结算后余额 − 扣注后余额；也等于相对开局前余额的盈亏。
    let netChange: Int
    /// 结算后打回玩家账户的筹码（含退本与派彩；输则为 0）。
    let amountReturned: Int
    /// 结算完成后的余额。
    let balanceAfter: Int

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
}

/// 独立结算模块：只做筹码算术，不碰发牌 / 动画状态机。
enum RoundSettlement {
    /// - Parameters:
    ///   - balanceAfterBet: 已扣除下注后的余额。
    ///   - betAmount: 本局下注（须 > 0）。
    ///   - outcome: 对局结果。
    /// - Returns: 结算明细；`balanceAfter` = 扣注后余额 + 退还额。
    static func settle(
        balanceAfterBet: Int,
        betAmount: Int,
        outcome: RoundOutcome
    ) -> SettlementResult {
        precondition(betAmount > 0, "betAmount must be positive")

        let profit: Int
        let amountReturned: Int
        switch outcome {
        case .playerBlackjack:
            // 退本 + 3:2 派彩
            profit = ChipRules.blackjackProfit(forBet: betAmount)
            amountReturned = betAmount + profit
        case .playerWin:
            profit = ChipRules.evenMoneyProfit(forBet: betAmount)
            amountReturned = betAmount + profit
        case .playerLose:
            profit = -betAmount
            amountReturned = 0
        case .push:
            profit = 0
            amountReturned = betAmount
        }

        return SettlementResult(
            betAmount: betAmount,
            outcome: outcome,
            netChange: profit,
            amountReturned: amountReturned,
            balanceAfter: balanceAfterBet + amountReturned
        )
    }
}
