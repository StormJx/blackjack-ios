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
}
