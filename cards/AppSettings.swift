//
//  AppSettings.swift
//  cards
//
//  E2：本地设置（默认副牌、切牌、音效/触觉）；桌限只读展示。
//

import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @Published var defaultPracticeMode: PracticeMode {
        didSet { persist() }
    }

    /// 开：现有切牌渗透率；关：每局打完后下一局必整副重洗（无渗透）。
    @Published var cutCardEnabled: Bool {
        didSet { persist() }
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
        static let cutCard = "appSettings.cutCardEnabled"
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

        if defaults.object(forKey: Keys.cutCard) != nil {
            cutCardEnabled = defaults.bool(forKey: Keys.cutCard)
        } else {
            cutCardEnabled = true
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

    /// 桌限只读文案（本迭代不改数值）。
    var tableLimitsSummary: String {
        let chips = ChipRules.betChipValues.map(String.init).joined(separator: " / ")
        return "最小注 \(ChipRules.minimumBet)；筹码档 \(chips)"
    }

    /// 设置变更后提示：对下一局生效。
    static let appliesNextRoundHint = "对下一局生效"

    private func persist() {
        defaults.set(defaultPracticeMode.rawValue, forKey: Keys.practiceMode)
        defaults.set(cutCardEnabled, forKey: Keys.cutCard)
        defaults.set(soundEnabled, forKey: Keys.sound)
        defaults.set(hapticsEnabled, forKey: Keys.haptics)
    }
}
