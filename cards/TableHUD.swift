//
//  TableHUD.swift
//  cards
//
//  牌桌顶栏目标 + 状态条阶段文案（不替代局末结果 / 道具提示）。
//

import Foundation

enum TableHUD {
    /// 顶栏只写关卡/阶名。庄家池数字留在余额行，避免同一数字出现两次。
    static func goalLine(playStyle: PlayStyle, level: Int) -> String {
        switch playStyle {
        case .challenge:
            return ChallengeRules.stage(level: level).title
        case .entertainment:
            return EntertainmentRules.stage(level: level).title
        }
    }

    static func phaseStatusLine(phase: BlackjackGame.Phase) -> String {
        switch phase {
        case .idle:
            return L10n.t("table.status.pickBet")
        case .dealing:
            return L10n.t("table.status.dealing")
        case .insuranceOffer:
            return L10n.t("table.status.insurance")
        case .playerTurn:
            return L10n.t("table.status.yourTurn")
        case .dealerTurn:
            return L10n.t("table.status.dealerTurn")
        case .finished:
            return L10n.t("table.roundOver")
        }
    }

    static func phaseStatusIcon(phase: BlackjackGame.Phase) -> String {
        switch phase {
        case .idle:
            return "banknote"
        case .dealing:
            return "rectangle.stack"
        case .insuranceOffer:
            return "shield"
        case .playerTurn:
            return "hand.tap.fill"
        case .dealerTurn:
            return "person.fill"
        case .finished:
            return "checkmark.circle"
        }
    }

    /// 庄家池从满到空的比例。超出开局池时停在 1。
    static func dealerBankFraction(remaining: Int, capacity: Int) -> Double {
        guard capacity > 0 else { return 0 }
        let clamped = min(capacity, max(0, remaining))
        return Double(clamped) / Double(capacity)
    }
}
