//
//  TableHUD.swift
//  cards
//
//  牌桌顶栏目标 + 状态条阶段文案（不替代局末结果 / 道具提示）。
//

import Foundation

enum TableHUD {
    static func goalLine(playStyle: PlayStyle, level: Int, dealerRemaining: Int) -> String {
        let title: String
        switch playStyle {
        case .challenge:
            title = ChallengeRules.stage(level: level).title
        case .entertainment:
            title = EntertainmentRules.stage(level: level).title
        }
        return L10n.format("table.goal.remainingFormat", title, dealerRemaining)
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
}
