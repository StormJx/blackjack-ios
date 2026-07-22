//
//  PlayStyle.swift
//  cards
//
//  闯关挑战（筹码进阶）与娱乐模式（筹码 + 玩法道具）正交于 PracticeMode（副牌数）。
//

import Foundation

/// 对局玩法：与牌副数独立；决定筹码进阶 / 道具是否可用。
enum PlayStyle: String, CaseIterable, Identifiable, Sendable {
    /// 闯关：庄家资金池 + 关卡进阶；不可用玩法道具。
    case challenge
    /// 娱乐：有筹码、可使用已解锁玩法道具（原「快速练习」）。
    /// - Note: rawValue 保持 `fast` 以兼容既有存档键 / 测试，界面文案为「娱乐」。
    case entertainment = "fast"

    var id: String { rawValue }

    var welcomeButtonTitle: String {
        switch self {
        case .challenge: return "闯关挑战"
        case .entertainment: return "娱乐模式"
        }
    }

    var welcomeSubtitle: String {
        switch self {
        case .challenge:
            return ChipRules.challengeWelcomeSummary
        case .entertainment:
            return "休闲对局；已解锁道具可在此使用。局末同样结算筹码。"
        }
    }

    /// 两种模式均有筹码下注。
    var showsChips: Bool { true }

    /// 影响胜负的玩法道具（如见牌后再全下）仅娱乐模式可用。
    var allowsGameplayProps: Bool { self == .entertainment }

    var continueButtonTitle: String {
        switch self {
        case .challenge: return "继续"
        case .entertainment: return "继续"
        }
    }

    var abandonConfirmDetail: String {
        switch self {
        case .challenge:
            return ChipRules.abandonSessionConfirmDetail
        case .entertainment:
            return "将清空本会话娱乐筹码并返回主页（闯关进度不受影响）。"
        }
    }

    var abandonConfirmButtonTitle: String {
        switch self {
        case .challenge: return "退出并清空筹码"
        case .entertainment: return "退出会话"
        }
    }

    /// 成就轨：娱乐对局仍记入原 practice 轨。
    var achievementScope: AchievementScope {
        switch self {
        case .challenge: return .challenge
        case .entertainment: return .practice
        }
    }
}
