//
//  RoundSettlement.swift
//  cards
//
//  阶段 3 / 3.5：纯函数结算。下注已从玩家余额扣出后调用；含庄家池不足额赔付。
//  P6+：可选保险侧注（先结算保险，再结算主注）。
//

import Foundation

/// 一局筹码结算结果（可供 UI 与单测直接断言）。
struct SettlementResult: Equatable, Sendable {
    /// 本局主注额。
    let betAmount: Int
    /// 胜负类别（主注）。
    let outcome: RoundOutcome
    /// 相对「扣主注与保险后余额」的净变动（主注 + 保险；赢为正、输为负）。
    /// 不足额赔付时，正值可能小于足额派彩。
    let netChange: Int
    /// 结算后打回玩家账户的筹码（主注退本/派彩 + 保险退本/派彩；皆无则为 0）。
    let amountReturned: Int
    /// 结算完成后的玩家余额。
    let balanceAfter: Int
    /// 结算完成后的庄家筹码池。
    let dealerBankAfter: Int
    /// 主注足额时应得利润（不含本金）；用于判断是否部分赔付。
    let idealProfit: Int
    /// 主注实际从庄家池支付的利润（输/平/投降为 0）。
    let profitPaid: Int
    /// 本局保险侧注（0 表示未买）。
    let insuranceBet: Int
    /// 保险净变动（赢为利润、输为 −侧注、未买为 0）。
    let insuranceNetChange: Int
    /// 保险实际派彩利润（未中或未买为 0）。
    let insuranceProfitPaid: Int

    /// 赢牌或保险赔付时庄家池不足以支付足额利润。
    var wasPartialPayout: Bool {
        let mainPartial: Bool
        switch outcome {
        case .playerBlackjack, .playerWin:
            mainPartial = profitPaid < idealProfit
        case .playerLose, .push, .playerSurrender:
            mainPartial = false
        }
        let insuranceIdeal = ChipRules.insuranceProfit(forInsuranceBet: insuranceBet)
        let insurancePartial = insuranceBet > 0
            && insuranceNetChange > 0
            && insuranceProfitPaid < insuranceIdeal
        return mainPartial || insurancePartial
    }

    /// 局末弹窗「本局盈亏」文案。
    var netChangeLabel: String {
        if netChange > 0 { return "+\(netChange)" }
        if netChange < 0 { return "\(netChange)" }
        if outcome == .push && insuranceBet == 0 {
            return "0（平局退注）"
        }
        return "0"
    }

    /// 主注赔率说明：黑杰克写明 3:2；普通胜写明 1:1；投降写明退半注；其余为 nil。
    var oddsLabel: String? {
        switch outcome {
        case .playerBlackjack:
            return ChipRules.blackjackOddsLabel
        case .playerWin:
            return ChipRules.evenMoneyOddsLabel
        case .playerSurrender:
            return ChipRules.surrenderOddsLabel
        case .playerLose, .push:
            return nil
        }
    }

    /// 保险侧注说明（未买为 nil）。
    var insuranceLabel: String? {
        guard insuranceBet > 0 else { return nil }
        if insuranceNetChange > 0 { return ChipRules.insuranceOddsLabel }
        return ChipRules.insuranceLostLabel
    }

    /// 不足额赔付时的补充说明。
    var partialPayoutLabel: String? {
        wasPartialPayout ? ChipRules.partialPayoutLabel : nil
    }
}

/// 独立结算模块：只做筹码算术，不碰发牌 / 动画状态机。
enum RoundSettlement {
    /// - Parameters:
    ///   - balanceAfterBet: 已扣除主注与保险侧注后的玩家余额。
    ///   - betAmount: 本局主注（须 > 0）。
    ///   - dealerBank: 结算前庄家筹码池（须 ≥ 0）。
    ///   - outcome: 主注对局结果。
    ///   - insuranceBet: 已扣出的保险侧注（0 表示未买）。
    ///   - insuranceWon: 庄家为黑杰克且已买保险时为 true。
    /// - Returns: 结算明细；先保险后主注；赢时利润 = min(应付利润, 当时庄家池)。
    static func settle(
        balanceAfterBet: Int,
        betAmount: Int,
        dealerBank: Int,
        outcome: RoundOutcome,
        insuranceBet: Int = 0,
        insuranceWon: Bool = false
    ) -> SettlementResult {
        precondition(betAmount > 0, "betAmount must be positive")
        precondition(dealerBank >= 0, "dealerBank must be non-negative")
        precondition(insuranceBet >= 0, "insuranceBet must be non-negative")

        var workingBalance = balanceAfterBet
        var workingDealer = dealerBank
        var insuranceNet = 0
        var insuranceProfitPaid = 0
        var insuranceReturned = 0

        if insuranceBet > 0 {
            if insuranceWon {
                let idealInsurance = ChipRules.insuranceProfit(forInsuranceBet: insuranceBet)
                insuranceProfitPaid = min(idealInsurance, workingDealer)
                insuranceReturned = insuranceBet + insuranceProfitPaid
                workingBalance += insuranceReturned
                workingDealer -= insuranceProfitPaid
                insuranceNet = insuranceProfitPaid
            } else {
                workingDealer += insuranceBet
                insuranceNet = -insuranceBet
            }
        }

        let ideal = ChipRules.idealProfit(forBet: betAmount, outcome: outcome)
        let profitPaid: Int
        let mainReturned: Int
        let dealerBankAfter: Int
        let mainNet: Int

        switch outcome {
        case .playerBlackjack, .playerWin:
            profitPaid = min(ideal, workingDealer)
            mainReturned = betAmount + profitPaid
            dealerBankAfter = workingDealer - profitPaid
            mainNet = profitPaid
        case .playerLose:
            profitPaid = 0
            mainReturned = 0
            dealerBankAfter = workingDealer + betAmount
            mainNet = -betAmount
        case .playerSurrender:
            profitPaid = 0
            let refund = betAmount / 2
            mainReturned = refund
            dealerBankAfter = workingDealer + (betAmount - refund)
            mainNet = -refund
        case .push:
            profitPaid = 0
            mainReturned = betAmount
            dealerBankAfter = workingDealer
            mainNet = 0
        }

        let amountReturned = mainReturned + insuranceReturned
        return SettlementResult(
            betAmount: betAmount,
            outcome: outcome,
            netChange: mainNet + insuranceNet,
            amountReturned: amountReturned,
            balanceAfter: workingBalance + mainReturned,
            dealerBankAfter: dealerBankAfter,
            idealProfit: ideal,
            profitPaid: profitPaid,
            insuranceBet: insuranceBet,
            insuranceNetChange: insuranceNet,
            insuranceProfitPaid: insuranceProfitPaid
        )
    }
}
