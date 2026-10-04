//
//  ActionHint.swift
//  cards
//
//  T4：把基础策略动作写成一句弱提示。不执行操作。
//

import Foundation

enum ActionHint {
    static func line(for action: StrategyAction) -> String {
        switch action {
        case .hit:
            return L10n.t("hint.action.hit")
        case .stand:
            return L10n.t("hint.action.stand")
        case .double:
            return L10n.t("hint.action.double")
        case .surrender:
            return L10n.t("hint.action.surrender")
        case .split:
            return L10n.t("hint.action.split")
        }
    }
}
