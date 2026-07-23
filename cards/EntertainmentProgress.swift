//
//  EntertainmentProgress.swift
//  cards
//
//  娱乐模式进阶：打穿庄家（或累计赢码）解锁更高双方起始筹码与注码档。
//

import Foundation
import SwiftUI

/// 娱乐单关：起始筹码 + 本关注码三档。
struct EntertainmentStage: Equatable, Sendable, Identifiable {
    let level: Int
    let playerStart: Int
    let dealerStart: Int
    let minimumBet: Int
    let betChipValues: [Int]
    let title: String

    var id: Int { level }

    var tableLimitsSummary: String {
        let chips = betChipValues.map(String.init).joined(separator: " / ")
        return "最小注 \(minimumBet)；筹码档 \(chips)"
    }
}

enum EntertainmentRules {
    static let stages: [EntertainmentStage] = [
        EntertainmentStage(
            level: 1,
            playerStart: 1000,
            dealerStart: 2000,
            minimumBet: 100,
            betChipValues: [100, 200, 500],
            title: "娱乐一阶"
        ),
        EntertainmentStage(
            level: 2,
            playerStart: 2000,
            dealerStart: 5000,
            minimumBet: 100,
            betChipValues: [200, 400, 800],
            title: "娱乐二阶"
        ),
        EntertainmentStage(
            level: 3,
            playerStart: 3500,
            dealerStart: 9000,
            minimumBet: 200,
            betChipValues: [200, 500, 1000],
            title: "娱乐三阶"
        ),
        EntertainmentStage(
            level: 4,
            playerStart: 5500,
            dealerStart: 16_000,
            minimumBet: 250,
            betChipValues: [250, 750, 1500],
            title: "娱乐四阶"
        ),
        EntertainmentStage(
            level: 5,
            playerStart: 8000,
            dealerStart: 25_000,
            minimumBet: 500,
            betChipValues: [500, 1000, 2000],
            title: "娱乐终阶"
        ),
    ]

    static var maxLevel: Int { stages.last?.level ?? 1 }

    static func stage(level: Int) -> EntertainmentStage {
        stages.first { $0.level == level } ?? stages[0]
    }

    /// 打穿次数或娱乐累计赢码（取较高关）。
    static func computedUnlockedLevel(dealerClears: Int, totalChipsWon: Int) -> Int {
        var level = 1
        if dealerClears >= 1 || totalChipsWon >= 2000 { level = max(level, 2) }
        if dealerClears >= 2 || totalChipsWon >= 5000 { level = max(level, 3) }
        if dealerClears >= 3 || totalChipsWon >= 10_000 { level = max(level, 4) }
        if dealerClears >= 5 || totalChipsWon >= 20_000 { level = max(level, 5) }
        return min(level, maxLevel)
    }

    static func nextStageThreshold(afterLevel level: Int) -> (clears: Int, chipsWon: Int)? {
        switch level {
        case 1: return (1, 2000)
        case 2: return (2, 5000)
        case 3: return (3, 10_000)
        case 4: return (5, 20_000)
        default: return nil
        }
    }

    static func progressHint(
        unlockedLevel: Int,
        dealerClears: Int,
        totalChipsWon: Int
    ) -> String {
        let stage = stage(level: unlockedLevel)
        guard let next = nextStageThreshold(afterLevel: unlockedLevel) else {
            return "\(stage.title)：已通关全部阶梯"
        }
        let clearsLeft = max(0, next.clears - dealerClears)
        let chipsLeft = max(0, next.chipsWon - totalChipsWon)
        return "\(stage.title)：下一阶再打穿 \(clearsLeft) 次，或再赢 \(chipsLeft) 筹码"
    }
}

/// 娱乐进阶进度（与闯关轨独立；不计入闯关成就）。
@MainActor
final class EntertainmentProgress: ObservableObject {
    @Published private(set) var unlockedLevel: Int
    @Published private(set) var dealerClearCount: Int
    @Published private(set) var totalChipsWon: Int

    private let defaults: UserDefaults

    private enum Keys {
        static let unlocked = "entertainment.unlockedLevel"
        static let clears = "entertainment.dealerClearCount"
        static let chipsWon = "entertainment.totalChipsWon"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedLevel = defaults.object(forKey: Keys.unlocked) == nil
            ? 1
            : max(1, defaults.integer(forKey: Keys.unlocked))
        unlockedLevel = min(storedLevel, EntertainmentRules.maxLevel)
        dealerClearCount = max(0, defaults.integer(forKey: Keys.clears))
        totalChipsWon = max(0, defaults.integer(forKey: Keys.chipsWon))
        _ = recomputeLevel()
    }

    var currentStage: EntertainmentStage {
        EntertainmentRules.stage(level: unlockedLevel)
    }

    /// 结算净赢计入娱乐累计（仅正数）。
    func recordChipsWon(_ netChange: Int) {
        guard netChange > 0 else { return }
        totalChipsWon += netChange
        _ = recomputeLevel()
        persist()
    }

    /// 娱乐会话打穿庄家池。
    @discardableResult
    func recordDealerCleared() -> Bool {
        dealerClearCount += 1
        let leveled = recomputeLevel()
        persist()
        return leveled
    }

    @discardableResult
    private func recomputeLevel() -> Bool {
        let computed = EntertainmentRules.computedUnlockedLevel(
            dealerClears: dealerClearCount,
            totalChipsWon: totalChipsWon
        )
        guard computed > unlockedLevel else { return false }
        unlockedLevel = computed
        return true
    }

    private func persist() {
        defaults.set(unlockedLevel, forKey: Keys.unlocked)
        defaults.set(dealerClearCount, forKey: Keys.clears)
        defaults.set(totalChipsWon, forKey: Keys.chipsWon)
    }
}
