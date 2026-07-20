//
//  PlayStyle.swift
//  cards
//
//  E1：挑战庄家（筹码）与快速练习（无下注）正交于 PracticeMode（副牌数）。
//

import Foundation

/// 对局玩法：与牌副数独立；决定是否走筹码 / 下注流程。
enum PlayStyle: String, CaseIterable, Identifiable, Sendable {
    /// 默认：庄家资金池 + 下注结算。
    case challenge
    /// 快速：无筹码，只记本会话胜负反馈。
    case fast

    var id: String { rawValue }

    var welcomeButtonTitle: String {
        switch self {
        case .challenge: return "挑战庄家"
        case .fast: return "快速练习"
        }
    }

    var welcomeSubtitle: String {
        switch self {
        case .challenge:
            return ChipRules.welcomeRulesSummary
        case .fast:
            return "无筹码，只练决策；局末看胜负与本会话连胜。"
        }
    }

    var showsChips: Bool { self == .challenge }

    /// 局末主按钮文案（体验优化：快速用「下一局」）。
    var continueButtonTitle: String {
        switch self {
        case .challenge: return "继续"
        case .fast: return "下一局"
        }
    }

    var abandonConfirmDetail: String {
        switch self {
        case .challenge:
            return ChipRules.abandonSessionConfirmDetail
        case .fast:
            return "将结束本会话并返回主页。快速练习不保存筹码进度。"
        }
    }

    var abandonConfirmButtonTitle: String {
        switch self {
        case .challenge: return "退出并清空筹码"
        case .fast: return "退出会话"
        }
    }
}
