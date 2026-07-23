//
//  ChallengeProgress.swift
//  cards
//
//  闯关：打穿庄家或累计赢筹码解锁更高双方起始筹码。
//

import Foundation
import SwiftUI

/// 单关配置。
struct ChallengeStage: Equatable, Sendable, Identifiable {
    let level: Int
    let playerStart: Int
    let dealerStart: Int
    let title: String

    var id: Int { level }
}

enum ChallengeRules {
    static let stages: [ChallengeStage] = [
        ChallengeStage(level: 1, playerStart: 1000, dealerStart: 2000, title: "第一关"),
        ChallengeStage(level: 2, playerStart: 1500, dealerStart: 4000, title: "第二关"),
        ChallengeStage(level: 3, playerStart: 2500, dealerStart: 7000, title: "第三关"),
        ChallengeStage(level: 4, playerStart: 4000, dealerStart: 12_000, title: "第四关"),
        ChallengeStage(level: 5, playerStart: 6000, dealerStart: 20_000, title: "终关"),
    ]

    static var maxLevel: Int { stages.last?.level ?? 1 }

    static func stage(level: Int) -> ChallengeStage {
        stages.first { $0.level == level } ?? stages[0]
    }

    /// 按打穿次数与累计赢筹码推算应解锁到的关卡（取较高者）。
    static func computedUnlockedLevel(dealerClears: Int, totalChipsWon: Int) -> Int {
        var level = 1
        if dealerClears >= 1 || totalChipsWon >= 2000 { level = max(level, 2) }
        if dealerClears >= 2 || totalChipsWon >= 5000 { level = max(level, 3) }
        if dealerClears >= 3 || totalChipsWon >= 10_000 { level = max(level, 4) }
        if dealerClears >= 5 || totalChipsWon >= 20_000 { level = max(level, 5) }
        return min(level, maxLevel)
    }

    /// 下一关解锁门槛（打穿次数、累计赢筹码）；已满级返回 `nil`。
    static func nextStageThreshold(afterLevel level: Int) -> (clears: Int, chipsWon: Int)? {
        switch level {
        case 1: return (1, 2000)
        case 2: return (2, 5000)
        case 3: return (3, 10_000)
        case 4: return (5, 20_000)
        default: return nil
        }
    }

    /// 欢迎页弱提示：当前关 + 距下一关差额（F2）。
    static func progressHint(
        unlockedLevel: Int,
        dealerClears: Int,
        totalChipsWon: Int
    ) -> String {
        let stage = stage(level: unlockedLevel)
        guard let next = nextStageThreshold(afterLevel: unlockedLevel) else {
            return "\(stage.title)：已通关全部关卡"
        }
        let clearsLeft = max(0, next.clears - dealerClears)
        let chipsLeft = max(0, next.chipsWon - totalChipsWon)
        return "\(stage.title)：下一关再打穿 \(clearsLeft) 次或再累计赢 \(chipsLeft)"
    }
}

/// 闯关进度：已解锁最高关（持久化）。
@MainActor
final class ChallengeProgress: ObservableObject {
    @Published private(set) var unlockedLevel: Int

    private let defaults: UserDefaults

    private enum Keys {
        static let unlocked = "challenge.unlockedLevel"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.object(forKey: Keys.unlocked) == nil
            ? 1
            : max(1, defaults.integer(forKey: Keys.unlocked))
        unlockedLevel = min(stored, ChallengeRules.maxLevel)
    }

    var currentStage: ChallengeStage {
        ChallengeRules.stage(level: unlockedLevel)
    }

    /// 用战绩重新对齐解锁关卡（打穿 / 累计赢）；返回是否提升。
    @discardableResult
    func syncFromStats(dealerClears: Int, totalChipsWon: Int) -> Bool {
        let computed = ChallengeRules.computedUnlockedLevel(
            dealerClears: dealerClears,
            totalChipsWon: totalChipsWon
        )
        guard computed > unlockedLevel else { return false }
        unlockedLevel = computed
        persist()
        return true
    }

    private func persist() {
        defaults.set(unlockedLevel, forKey: Keys.unlocked)
    }
}
