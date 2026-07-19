//
//  RoundOutcome.swift
//  cards
//
//  对局结果枚举：仅描述胜负类型，不含筹码数字。供结算模块消费。
//

import Foundation

/// 一局结束后的胜负类别（与发牌状态机解耦；由 BlackjackGame 在结算时写入）。
enum RoundOutcome: Equatable, Sendable {
    /// 玩家天然黑杰克且庄家非黑杰克 → 赔率 3:2。
    case playerBlackjack
    /// 玩家普通获胜（含庄家爆牌、比点大）。
    case playerWin
    /// 玩家输（含爆牌、比点小）。
    case playerLose
    /// 平局（含双方黑杰克）→ 退回本金。
    case push

    /// 双方停牌后的比点（不含天然黑杰克、玩家中途爆牌）。
    static func fromFinalPoints(playerBest: Int, dealerBest: Int) -> RoundOutcome {
        if dealerBest > 21 { return .playerWin }
        if playerBest > dealerBest { return .playerWin }
        if playerBest < dealerBest { return .playerLose }
        return .push
    }

    /// 结果区 SF Symbol 名（UI 着色见 `statusColor`）。
    var statusIconName: String {
        switch self {
        case .playerBlackjack, .playerWin:
            return "checkmark.circle.fill"
        case .playerLose:
            return "xmark.circle.fill"
        case .push:
            return "equal.circle.fill"
        }
    }
}
