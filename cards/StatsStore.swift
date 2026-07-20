//
//  StatsStore.swift
//  cards
//
//  E3：挑战 / 练习分轨战绩与成就持久化。
//

import Foundation
import SwiftUI

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var challenge: ModeProgress
    @Published private(set) var practice: ModeProgress
    @Published private(set) var totalChipsWon: Int
    @Published private(set) var totalChipsLost: Int
    @Published private(set) var dealerBankClearCount: Int
    @Published private(set) var unlockedIDs: Set<AchievementID>
    @Published private(set) var pendingUnlockTitles: [String] = []

    private let defaults: UserDefaults

    private enum Keys {
        static let chipsWon = "stats.totalChipsWon"
        static let chipsLost = "stats.totalChipsLost"
        static let dealerClears = "stats.dealerBankClearCount"
        static let unlocked = "stats.unlockedAchievements"

        static let cRounds = "stats.challenge.rounds"
        static let cWins = "stats.challenge.wins"
        static let cLosses = "stats.challenge.losses"
        static let cPushes = "stats.challenge.pushes"
        static let cWinStreak = "stats.challenge.currentWinStreak"
        static let cBestStreak = "stats.challenge.bestWinStreak"
        static let cNoBust = "stats.challenge.currentNoBustStreak"
        static let cBestNoBust = "stats.challenge.bestNoBustStreak"
        static let cDealerBust = "stats.challenge.dealerBustWinCount"
        static let cNaturalBJ = "stats.challenge.naturalBlackjackCount"
        static let cFiveCard = "stats.challenge.fiveCardCharlieCount"
        static let cAllInWins = "stats.challenge.allInWinCount"

        static let pRounds = "stats.practice.rounds"
        static let pWins = "stats.practice.wins"
        static let pLosses = "stats.practice.losses"
        static let pPushes = "stats.practice.pushes"
        static let pWinStreak = "stats.practice.currentWinStreak"
        static let pBestStreak = "stats.practice.bestWinStreak"
        static let pNoBust = "stats.practice.currentNoBustStreak"
        static let pBestNoBust = "stats.practice.bestNoBustStreak"
        static let pDealerBust = "stats.practice.dealerBustWinCount"
        static let pNaturalBJ = "stats.practice.naturalBlackjackCount"
        static let pFiveCard = "stats.practice.fiveCardCharlieCount"
        static let pAllInWins = "stats.practice.allInWinCount"

        // 旧版混计键（迁移到挑战轨）
        static let legacyRounds = "stats.totalRounds"
        static let legacyWins = "stats.totalWins"
        static let legacyLosses = "stats.totalLosses"
        static let legacyPushes = "stats.totalPushes"
        static let legacyBestStreak = "stats.bestWinStreak"
        static let legacyDealerBust = "stats.dealerBustWinCount"
        static let legacyPushCount = "stats.pushCount"
        static let legacyWinStreak = "stats.currentWinStreak"
        static let legacyNoBust = "stats.currentNoBustStreak"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        totalChipsWon = max(0, defaults.integer(forKey: Keys.chipsWon))
        totalChipsLost = max(0, defaults.integer(forKey: Keys.chipsLost))
        dealerBankClearCount = max(0, defaults.integer(forKey: Keys.dealerClears))

        let raw = defaults.stringArray(forKey: Keys.unlocked) ?? []
        unlockedIDs = Set(raw.compactMap(AchievementID.init(rawValue:)))

        if defaults.object(forKey: Keys.cRounds) != nil {
            challenge = Self.loadMode(
                defaults: defaults,
                rounds: Keys.cRounds, wins: Keys.cWins, losses: Keys.cLosses, pushes: Keys.cPushes,
                winStreak: Keys.cWinStreak, bestStreak: Keys.cBestStreak,
                noBust: Keys.cNoBust, bestNoBust: Keys.cBestNoBust,
                dealerBust: Keys.cDealerBust, naturalBJ: Keys.cNaturalBJ, fiveCard: Keys.cFiveCard,
                allInWins: Keys.cAllInWins
            )
        } else {
            // 迁移：旧混计视为挑战进度；练习从 0 起。
            var migrated = ModeProgress()
            migrated.rounds = max(0, defaults.integer(forKey: Keys.legacyRounds))
            migrated.wins = max(0, defaults.integer(forKey: Keys.legacyWins))
            migrated.losses = max(0, defaults.integer(forKey: Keys.legacyLosses))
            migrated.pushes = max(
                defaults.integer(forKey: Keys.legacyPushes),
                defaults.integer(forKey: Keys.legacyPushCount)
            )
            migrated.currentWinStreak = max(0, defaults.integer(forKey: Keys.legacyWinStreak))
            migrated.bestWinStreak = max(0, defaults.integer(forKey: Keys.legacyBestStreak))
            migrated.currentNoBustStreak = max(0, defaults.integer(forKey: Keys.legacyNoBust))
            migrated.bestNoBustStreak = migrated.currentNoBustStreak
            migrated.dealerBustWinCount = max(0, defaults.integer(forKey: Keys.legacyDealerBust))
            challenge = migrated
        }

        practice = Self.loadMode(
            defaults: defaults,
            rounds: Keys.pRounds, wins: Keys.pWins, losses: Keys.pLosses, pushes: Keys.pPushes,
            winStreak: Keys.pWinStreak, bestStreak: Keys.pBestStreak,
            noBust: Keys.pNoBust, bestNoBust: Keys.pBestNoBust,
            dealerBust: Keys.pDealerBust, naturalBJ: Keys.pNaturalBJ, fiveCard: Keys.pFiveCard,
            allInWins: Keys.pAllInWins
        )
    }

    var hasAnyHistory: Bool {
        challenge.rounds > 0 || practice.rounds > 0
            || totalChipsWon > 0 || totalChipsLost > 0 || !unlockedIDs.isEmpty
    }

    func progressInput(for scope: AchievementScope) -> AchievementProgressInput {
        AchievementProgressInput(
            mode: scope == .challenge ? challenge : practice,
            totalChipsWon: totalChipsWon,
            dealerBankClearCount: dealerBankClearCount,
            unlocked: unlockedIDs
        )
    }

    func chipsSummaryLine() -> String {
        "累计赢 \(totalChipsWon) · 累计亏 \(totalChipsLost) · 打穿庄家 \(dealerBankClearCount) 次"
    }

    func recordSummaryLine(for scope: AchievementScope) -> String {
        let m = scope == .challenge ? challenge : practice
        return "\(m.wins) 胜 · \(m.losses) 负 · \(m.pushes) 平 · 最长连胜 \(m.bestWinStreak)"
    }

    /// 挑战模式结算后写入总赢/总亏，并检查筹码阶梯成就。
    func recordChipSettlement(netChange: Int) {
        if netChange > 0 {
            totalChipsWon += netChange
        } else if netChange < 0 {
            totalChipsLost += -netChange
        }
        unlockChipMilestones()
        persist()
    }

    /// 打穿庄家池（会话结束原因为 dealerBroke）。
    func recordDealerBankCleared() {
        dealerBankClearCount += 1
        unlockChipMilestones()
        persist()
    }

    /// 按模式记录一局；练习局不会解锁挑战成就，反之亦然。
    @discardableResult
    func recordRound(snapshot: RoundSnapshot, scope: AchievementScope) -> [AchievementID] {
        var input = progressInput(for: scope)
        let newly = AchievementEvaluator.evaluate(
            snapshot: snapshot,
            scope: scope,
            progress: &input
        )

        if scope == .challenge {
            challenge = input.mode
        } else {
            practice = input.mode
        }
        unlockedIDs = input.unlocked

        if !newly.isEmpty {
            pendingUnlockTitles.append(contentsOf: newly.map(\.title))
        }
        persist()
        return newly
    }

    func consumePendingUnlocks() -> [String] {
        let titles = pendingUnlockTitles
        pendingUnlockTitles = []
        return titles
    }

    func clearPendingUnlocks() {
        pendingUnlockTitles = []
    }

    private func unlockChipMilestones() {
        func unlock(_ id: AchievementID) {
            guard id.scope == .challenge else { return }
            guard !unlockedIDs.contains(id) else { return }
            unlockedIDs.insert(id)
            pendingUnlockTitles.append(id.title)
        }
        if totalChipsWon >= 1000 { unlock(.chipsWon1000) }
        if totalChipsWon >= 5000 { unlock(.chipsWon5000) }
        if totalChipsWon >= 20000 { unlock(.chipsWon20000) }
        if dealerBankClearCount >= 1 { unlock(.dealerClear1) }
        if dealerBankClearCount >= 5 { unlock(.dealerClear5) }
    }

    private static func loadMode(
        defaults: UserDefaults,
        rounds: String, wins: String, losses: String, pushes: String,
        winStreak: String, bestStreak: String,
        noBust: String, bestNoBust: String,
        dealerBust: String, naturalBJ: String, fiveCard: String,
        allInWins: String
    ) -> ModeProgress {
        ModeProgress(
            rounds: max(0, defaults.integer(forKey: rounds)),
            wins: max(0, defaults.integer(forKey: wins)),
            losses: max(0, defaults.integer(forKey: losses)),
            pushes: max(0, defaults.integer(forKey: pushes)),
            currentWinStreak: max(0, defaults.integer(forKey: winStreak)),
            bestWinStreak: max(0, defaults.integer(forKey: bestStreak)),
            currentNoBustStreak: max(0, defaults.integer(forKey: noBust)),
            bestNoBustStreak: max(0, defaults.integer(forKey: bestNoBust)),
            dealerBustWinCount: max(0, defaults.integer(forKey: dealerBust)),
            naturalBlackjackCount: max(0, defaults.integer(forKey: naturalBJ)),
            fiveCardCharlieCount: max(0, defaults.integer(forKey: fiveCard)),
            allInWinCount: max(0, defaults.integer(forKey: allInWins))
        )
    }

    private func persist() {
        defaults.set(totalChipsWon, forKey: Keys.chipsWon)
        defaults.set(totalChipsLost, forKey: Keys.chipsLost)
        defaults.set(dealerBankClearCount, forKey: Keys.dealerClears)
        defaults.set(unlockedIDs.map(\.rawValue).sorted(), forKey: Keys.unlocked)
        persistMode(challenge, prefix: "c")
        persistMode(practice, prefix: "p")
    }

    private func persistMode(_ m: ModeProgress, prefix: String) {
        let map: [(String, Int)] = prefix == "c"
            ? [
                (Keys.cRounds, m.rounds), (Keys.cWins, m.wins), (Keys.cLosses, m.losses),
                (Keys.cPushes, m.pushes), (Keys.cWinStreak, m.currentWinStreak),
                (Keys.cBestStreak, m.bestWinStreak), (Keys.cNoBust, m.currentNoBustStreak),
                (Keys.cBestNoBust, m.bestNoBustStreak), (Keys.cDealerBust, m.dealerBustWinCount),
                (Keys.cNaturalBJ, m.naturalBlackjackCount), (Keys.cFiveCard, m.fiveCardCharlieCount),
                (Keys.cAllInWins, m.allInWinCount),
            ]
            : [
                (Keys.pRounds, m.rounds), (Keys.pWins, m.wins), (Keys.pLosses, m.losses),
                (Keys.pPushes, m.pushes), (Keys.pWinStreak, m.currentWinStreak),
                (Keys.pBestStreak, m.bestWinStreak), (Keys.pNoBust, m.currentNoBustStreak),
                (Keys.pBestNoBust, m.bestNoBustStreak), (Keys.pDealerBust, m.dealerBustWinCount),
                (Keys.pNaturalBJ, m.naturalBlackjackCount), (Keys.pFiveCard, m.fiveCardCharlieCount),
                (Keys.pAllInWins, m.allInWinCount),
            ]
        for (key, value) in map {
            defaults.set(value, forKey: key)
        }
    }
}
