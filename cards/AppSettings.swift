//
//  AppSettings.swift
//  cards
//
//  E2 / P4 / P5 / F1：本地设置（默认副牌、切牌三态、桌限、全下解锁局数、音效/触觉）。
//

import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @Published var defaultPracticeMode: PracticeMode {
        didSet { persist() }
    }

    /// P5：闯关切牌三态；娱乐会话固定真实切牌，不受此项影响。
    @Published var cutCardMode: CutCardMode {
        didSet { persist() }
    }

    /// 桌限预设；对局中修改不热更新，返回主页后新开局生效。
    @Published var tableLimitPreset: TableLimitPreset {
        didSet { persist() }
    }

    /// F1：开局「全下」需本会话完成的局数（0 = 开局即可；默认 5）。两模式共用。
    @Published var preDealAllInUnlockRounds: Int {
        didSet {
            let clamped = ChipRules.clampPreDealAllInUnlockRounds(preDealAllInUnlockRounds)
            if clamped != preDealAllInUnlockRounds {
                preDealAllInUnlockRounds = clamped
                return
            }
            persist()
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            GameFeedback.shared.soundEnabled = soundEnabled
            persist()
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            GameFeedback.shared.hapticsEnabled = hapticsEnabled
            persist()
        }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let practiceMode = "appSettings.defaultPracticeMode"
        static let cutCardMode = "appSettings.cutCardMode"
        /// 旧布尔开关；迁移后仍可读一次。
        static let cutCardLegacy = "appSettings.cutCardEnabled"
        static let tableLimit = "appSettings.tableLimitPreset"
        static let allInUnlockRounds = "appSettings.preDealAllInUnlockRounds"
        static let sound = "appSettings.soundEnabled"
        static let haptics = "appSettings.hapticsEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Keys.practiceMode),
           let mode = PracticeMode(rawValue: raw) {
            defaultPracticeMode = mode
        } else {
            defaultPracticeMode = .singleDeck
        }

        if let raw = defaults.string(forKey: Keys.cutCardMode),
           let mode = CutCardMode(rawValue: raw) {
            cutCardMode = mode
        } else if defaults.object(forKey: Keys.cutCardLegacy) != nil {
            cutCardMode = defaults.bool(forKey: Keys.cutCardLegacy) ? .real : .off
        } else {
            cutCardMode = .real
        }

        if let raw = defaults.string(forKey: Keys.tableLimit),
           let preset = TableLimitPreset(rawValue: raw) {
            tableLimitPreset = preset
        } else {
            tableLimitPreset = .standard
        }

        if defaults.object(forKey: Keys.allInUnlockRounds) != nil {
            preDealAllInUnlockRounds = ChipRules.clampPreDealAllInUnlockRounds(
                defaults.integer(forKey: Keys.allInUnlockRounds)
            )
        } else {
            preDealAllInUnlockRounds = ChipRules.defaultPreDealAllInUnlockCompletedRounds
        }

        if defaults.object(forKey: Keys.sound) != nil {
            soundEnabled = defaults.bool(forKey: Keys.sound)
        } else {
            soundEnabled = true
        }

        if defaults.object(forKey: Keys.haptics) != nil {
            hapticsEnabled = defaults.bool(forKey: Keys.haptics)
        } else {
            hapticsEnabled = true
        }

        GameFeedback.shared.soundEnabled = soundEnabled
        GameFeedback.shared.hapticsEnabled = hapticsEnabled
    }

    /// 当前所选桌限文案（设置页展示；未必等于对局中已生效值）。
    var tableLimitsSummary: String {
        tableLimitPreset.summary
    }

    /// 设置变更后提示：牌副 / 切牌对下一局生效。
    static let appliesNextRoundHint = "对下一局生效"

    /// 桌限变更提示：须回主页再开新会话。
    static let tableLimitsApplyNextSessionHint = "返回主页后新开局生效"

    /// 全下解锁局数：新开局会话生效。
    static let allInUnlockAppliesNextSessionHint = "返回主页后新开局生效"

    private func persist() {
        defaults.set(defaultPracticeMode.rawValue, forKey: Keys.practiceMode)
        defaults.set(cutCardMode.rawValue, forKey: Keys.cutCardMode)
        defaults.set(tableLimitPreset.rawValue, forKey: Keys.tableLimit)
        defaults.set(preDealAllInUnlockRounds, forKey: Keys.allInUnlockRounds)
        defaults.set(soundEnabled, forKey: Keys.sound)
        defaults.set(hapticsEnabled, forKey: Keys.haptics)
    }
}
