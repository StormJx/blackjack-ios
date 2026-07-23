//
//  E1E4FeatureTests.swift
//  cardsTests
//
//  E1–E4 + 成就分轨 / 阶梯。
//

import Foundation
import Testing
@testable import cards

struct E1E4FeatureTests {

    // MARK: - E1 FastSessionStats

    @Test func fastStatsWinIncrementsStreak() {
        var stats = FastSessionStats()
        stats.record(.playerWin)
        stats.record(.playerBlackjack)
        #expect(stats.wins == 2)
        #expect(stats.currentWinStreak == 2)
        #expect(stats.roundsPlayed == 2)
    }

    @Test func fastStatsLossAndPushBreakStreak() {
        var stats = FastSessionStats()
        stats.record(.playerWin)
        stats.record(.playerLose)
        #expect(stats.currentWinStreak == 0)
        #expect(stats.losses == 1)
        stats.record(.playerWin)
        stats.record(.push)
        #expect(stats.currentWinStreak == 0)
        #expect(stats.pushes == 1)
    }

    // MARK: - E2 AppSettings + Deck cut

    @Test @MainActor
    func appSettingsPersistsAndReloads() {
        let suiteName = "cards.tests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.defaultPracticeMode = .shoe6
        settings.cutCardEnabled = false
        settings.soundEnabled = false
        settings.hapticsEnabled = false

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.defaultPracticeMode == .shoe6)
        #expect(reloaded.cutCardEnabled == false)
        #expect(reloaded.soundEnabled == false)
        #expect(reloaded.hapticsEnabled == false)
        #expect(reloaded.tableLimitPreset == .standard)
        #expect(reloaded.tableLimitsSummary.contains("100"))

        settings.tableLimitPreset = .light
        let reloadedLimits = AppSettings(defaults: defaults)
        #expect(reloadedLimits.tableLimitPreset == .light)
        #expect(reloadedLimits.tableLimitsSummary.contains("50"))
    }

    @Test func deckCutDisabledRequiresReshuffleAfterAnyDeal() {
        var d = Deck(numberOfDecks: 1, cutCardEnabled: false)
        var rng = SeededRNG(state: 11)
        d.shuffleAndCut(using: &rng)
        #expect(d.needsReshuffleBeforeNextRound == false)
        _ = d.draw()
        #expect(d.remainingCount < d.totalCardCount)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func deckCutEnabledStillHonorsPenetration() {
        var d = Deck(numberOfDecks: 1, cutCardEnabled: true)
        var rng = SeededRNG(state: 22)
        d.shuffleAndCut(using: &rng)
        for _ in 0..<3 { _ = d.draw() }
        if d.dealtCount < d.cutPosition {
            #expect(d.needsReshuffleBeforeNextRound == false)
        }
    }

    // MARK: - Achievements

    @Test func challengeFiveCardDoesNotUnlockPractice() {
        var progress = emptyProgress()
        let snap = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 5,
            playerBest: 18,
            dealerBest: 17,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        let newly = AchievementEvaluator.evaluate(
            snapshot: snap,
            scope: .challenge,
            progress: &progress
        )
        #expect(newly.contains(.fiveCardCharlie))
        #expect(!newly.contains(.practiceFiveCard))
    }

    @Test func practiceRoundDoesNotUnlockChallengeAchievements() {
        var progress = emptyProgress()
        let snap = RoundSnapshot(
            outcome: .playerBlackjack,
            playerCardCount: 2,
            playerBest: 21,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: true
        )
        let newly = AchievementEvaluator.evaluate(
            snapshot: snap,
            scope: .practice,
            progress: &progress
        )
        #expect(newly.contains(.practiceNaturalBJ))
        #expect(!newly.contains(.speedBlackjack))
        #expect(!newly.contains(.comeback))
    }

    @Test func practiceWinStreakAndVolumeLadders() {
        var progress = emptyProgress()
        progress.mode.bestWinStreak = 4
        progress.mode.currentWinStreak = 4
        progress.mode.wins = 19
        let snap = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 2,
            playerBest: 19,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        let newly = AchievementEvaluator.evaluate(
            snapshot: snap,
            scope: .practice,
            progress: &progress
        )
        #expect(progress.mode.bestWinStreak == 5)
        #expect(progress.mode.wins == 20)
        #expect(newly.contains(.practiceWinStreak5))
        #expect(newly.contains(.practiceWins20))
        #expect(!newly.contains(.winStreak5))
        #expect(!newly.contains(.wins10))
    }

    @Test func challengePushAndWinStreakLadders() {
        var progress = emptyProgress()
        progress.mode.pushes = 9
        progress.mode.bestWinStreak = 9
        progress.mode.currentWinStreak = 9

        let push = RoundSnapshot(
            outcome: .push,
            playerCardCount: 2,
            playerBest: 17,
            dealerBest: 17,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        var newly = AchievementEvaluator.evaluate(
            snapshot: push,
            scope: .challenge,
            progress: &progress
        )
        #expect(newly.contains(.push10))
        #expect(!newly.contains(.push20))
        // 平局打断连胜计数，但最长连胜仍保留，故可能已解锁较低档连胜成就
        #expect(progress.unlocked.contains(.winStreak3))
        #expect(progress.unlocked.contains(.winStreak5))

        progress.mode.currentWinStreak = 9
        progress.mode.bestWinStreak = 9
        let win = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 2,
            playerBest: 20,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        newly = AchievementEvaluator.evaluate(
            snapshot: win,
            scope: .challenge,
            progress: &progress
        )
        #expect(progress.mode.bestWinStreak == 10)
        #expect(newly.contains(.winStreak10))
        #expect(newly.contains(.comeback))
        #expect(progress.unlocked.contains(.winStreak10))
    }

    @Test func braveHitLadderRequiresWin() {
        var progress = emptyProgress()
        let lose = RoundSnapshot(
            outcome: .playerLose,
            playerCardCount: 3,
            playerBest: 20,
            dealerBest: 21,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false,
            hitSurvivedFromOver17: true,
            hitSurvivedFromOver18: true,
            hitSurvivedFromOver19: true,
            hitFrom20To21: true
        )
        var newly = AchievementEvaluator.evaluate(
            snapshot: lose,
            scope: .challenge,
            progress: &progress
        )
        #expect(!newly.contains(.braveHitOver17))

        let win = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 3,
            playerBest: 21,
            dealerBest: 19,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false,
            hitSurvivedFromOver17: true,
            hitSurvivedFromOver18: true,
            hitSurvivedFromOver19: true,
            hitFrom20To21: true
        )
        newly = AchievementEvaluator.evaluate(
            snapshot: win,
            scope: .challenge,
            progress: &progress
        )
        #expect(newly.contains(.braveHitOver17))
        #expect(newly.contains(.braveHit20To21))
    }

    @Test func firstHandWinUnlocksOnTwoCardNonBJ() {
        var progress = emptyProgress()
        let snap = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 2,
            playerBest: 19,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        let newly = AchievementEvaluator.evaluate(
            snapshot: snap,
            scope: .challenge,
            progress: &progress
        )
        #expect(newly.contains(.firstHandWin))
    }

    @Test @MainActor
    func statsStoreSeparatesChallengeAndPractice() {
        let suiteName = "cards.tests.stats.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = StatsStore(defaults: defaults)
        store.recordChipSettlement(netChange: 150)

        let challengeSnap = RoundSnapshot(
            outcome: .playerBlackjack,
            playerCardCount: 2,
            playerBest: 21,
            dealerBest: 16,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: true
        )
        let cNew = store.recordRound(snapshot: challengeSnap, scope: .challenge)
        #expect(cNew.contains(.speedBlackjack))
        #expect(store.challenge.wins == 1)
        #expect(store.practice.wins == 0)

        let practiceSnap = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 5,
            playerBest: 18,
            dealerBest: 17,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
        let pNew = store.recordRound(snapshot: practiceSnap, scope: .practice)
        #expect(pNew.contains(.practiceFiveCard))
        #expect(!pNew.contains(.fiveCardCharlie))
        #expect(store.practice.wins == 1)
        #expect(store.unlockedIDs.contains(.speedBlackjack))
        #expect(store.unlockedIDs.contains(.practiceFiveCard))

        store.recordChipSettlement(netChange: 900)
        #expect(store.totalChipsWon == 1050)
        #expect(store.unlockedIDs.contains(.chipsWon1000))

        let reloaded = StatsStore(defaults: defaults)
        #expect(reloaded.challenge.wins == 1)
        #expect(reloaded.practice.wins == 1)
        #expect(reloaded.unlockedIDs.contains(.chipsWon1000))
    }

    @Test func allInWinLadderUnlocks() {
        var progress = emptyProgress()
        progress.mode.allInWinCount = 4
        let snap = RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 2,
            playerBest: 20,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false,
            wasAllInBet: true
        )
        let newly = AchievementEvaluator.evaluate(
            snapshot: snap,
            scope: .challenge,
            progress: &progress
        )
        #expect(progress.mode.allInWinCount == 5)
        #expect(newly.contains(.allInWin5))
        #expect(!newly.contains(.allInWin15))
    }

    @Test func achievementCatalogCounts() {
        let challengeCount = AchievementID.ids(in: .challenge).count
        let practiceCount = AchievementID.ids(in: .practice).count
        #expect(challengeCount + practiceCount == AchievementID.allCases.count)
        #expect(challengeCount >= 30)
        #expect(practiceCount >= 10)
    }

    // MARK: - v1.9 Props (P1 + P9)

    @Test @MainActor
    func propStoreLockedUntilDealerClearAchievement() {
        let suiteName = "cards.tests.props.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        #expect(props.owns(.midHandAllIn) == false)

        let newly = props.syncFromAchievements([])
        #expect(newly.isEmpty)
        #expect(props.owns(.midHandAllIn) == false)

        let granted = props.syncFromAchievements([.dealerClear1])
        #expect(granted == [.midHandAllIn])
        #expect(props.owns(.midHandAllIn))

        // 幂等
        #expect(props.syncFromAchievements([.dealerClear1]).isEmpty)
        #expect(props.unlock(.midHandAllIn) == false)
    }

    @Test @MainActor
    func propStoreMigratesFromExistingDealerClearAchievement() {
        let suiteName = "cards.tests.props.migrate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set([AchievementID.dealerClear1.rawValue], forKey: "stats.unlockedAchievements")
        let props = PropStore(defaults: defaults)
        #expect(props.owns(.midHandAllIn))
    }

    @Test @MainActor
    func propStorePersistsOwnership() {
        let suiteName = "cards.tests.props.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        #expect(props.unlock(.midHandAllIn))
        let reloaded = PropStore(defaults: defaults)
        #expect(reloaded.owns(.midHandAllIn))
    }

    @Test @MainActor
    func recordDealerClearUnlocksMidHandProp() {
        let suiteName = "cards.tests.props.dealerClear.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stats = StatsStore(defaults: defaults)
        let props = PropStore(defaults: defaults)
        #expect(props.owns(.midHandAllIn) == false)

        stats.recordDealerBankCleared()
        #expect(stats.unlockedIDs.contains(.dealerClear1))
        let newly = props.syncFromAchievements(stats.unlockedIDs)
        #expect(newly == [.midHandAllIn])
        #expect(props.owns(.midHandAllIn))
    }

    @Test @MainActor
    func gameplayPropsOnlyInEntertainment() {
        let suiteName = "cards.tests.props.mode.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        #expect(props.unlock(.midHandAllIn))
        #expect(props.canUse(.midHandAllIn, in: .entertainment))
        #expect(props.canUse(.midHandAllIn, in: .challenge) == false)
    }

    @Test func challengeStagesUnlockByClearsOrChipsWon() {
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 0, totalChipsWon: 0) == 1)
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 1, totalChipsWon: 0) == 2)
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 0, totalChipsWon: 2000) == 2)
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 2, totalChipsWon: 0) == 3)
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 5, totalChipsWon: 0) == 5)
        #expect(ChallengeRules.computedUnlockedLevel(dealerClears: 0, totalChipsWon: 20_000) == 5)
        #expect(ChallengeRules.stage(level: 3).dealerStart == 7000)
    }

    @Test func challengeProgressHintShowsGapOrCleared() {
        let early = ChallengeRules.progressHint(
            unlockedLevel: 1,
            dealerClears: 0,
            totalChipsWon: 500
        )
        #expect(early.contains("第一关"))
        #expect(early.contains("1 次"))
        #expect(early.contains("1500"))

        let maxed = ChallengeRules.progressHint(
            unlockedLevel: 5,
            dealerClears: 5,
            totalChipsWon: 20_000
        )
        #expect(maxed.contains("已通关全部关卡"))
    }

    // MARK: - C1 Cosmetics / P4 Table limits / C2–C4 Props

    @Test @MainActor
    func cosmeticsUnlockByChallengeProgress() {
        let suiteName = "cards.tests.cosmetics.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = CosmeticsStore(defaults: defaults)
        #expect(store.owns(.classicNavy))
        #expect(store.owns(.emeraldLattice) == false)

        let emerald = store.syncFromProgress(unlockedLevel: 1, dealerClears: 1, totalChipsWon: 0)
        #expect(emerald == [.emeraldLattice])
        #expect(store.owns(.emeraldLattice))

        let crimson = store.syncFromProgress(unlockedLevel: 3, dealerClears: 1, totalChipsWon: 0)
        #expect(crimson == [.crimsonRibbon])
        store.select(.crimsonRibbon)
        #expect(store.selectedBack == .crimsonRibbon)

        let reloaded = CosmeticsStore(defaults: defaults)
        #expect(reloaded.owns(.crimsonRibbon))
        #expect(reloaded.selectedBack == .crimsonRibbon)
    }

    @Test func tableLimitPresetsAreValid() {
        for preset in TableLimitPreset.allCases {
            #expect(preset.betChipValues.count == 3)
            #expect(preset.betChipValues[0] == preset.minimumBet)
            #expect(preset.betChipValues[0] < preset.betChipValues[1])
            #expect(preset.betChipValues[1] < preset.betChipValues[2])
        }
        ActiveTableLimits.apply(.light)
        #expect(ChipRules.minimumBet == 50)
        #expect(ChipRules.betChipValues == [50, 100, 250])
        ActiveTableLimits.apply(.standard)
        #expect(ChipRules.minimumBet == 100)
    }

    @Test @MainActor
    func entertainmentProgressUnlocksStagesAndBets() {
        let suiteName = "cards.tests.ent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = EntertainmentProgress(defaults: defaults)
        #expect(progress.unlockedLevel == 1)
        #expect(progress.currentStage.betChipValues == [100, 200, 500])

        progress.recordChipsWon(2000)
        #expect(progress.unlockedLevel == 2)
        #expect(progress.currentStage.betChipValues == [200, 400, 800])

        _ = progress.recordDealerCleared() // clears = 1，仍为 2 阶
        #expect(progress.unlockedLevel == 2)
        #expect(progress.recordDealerCleared()) // clears = 2 → 3 阶
        #expect(progress.unlockedLevel == 3)
        #expect(progress.currentStage.minimumBet == 200)

        let reloaded = EntertainmentProgress(defaults: defaults)
        #expect(reloaded.unlockedLevel == 3)
        #expect(reloaded.dealerClearCount == 2)
    }

    @Test func deckReturnCardToShoeIncreasesRemaining() {
        var deck = Deck(numberOfDecks: 1, cutCardEnabled: true)
        var rng = SeededRNG(state: 42)
        deck.shuffleAndCut(using: &rng)
        let before = deck.remainingCount
        guard let card = deck.draw() else {
            Issue.record("expected a card")
            return
        }
        #expect(deck.remainingCount == before - 1)
        deck.returnCardToShoe(card, using: &rng)
        #expect(deck.remainingCount == before)
    }

    @Test func handSoftSeventeenDetection() {
        let soft17 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .six),
        ])
        #expect(soft17.isSoftSeventeen)
        #expect(soft17.isSoft)

        let hard17 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .spades, rank: .seven),
        ])
        #expect(hard17.bestValue == 17)
        #expect(hard17.isSoftSeventeen == false)
    }

    @Test @MainActor
    func propStoreUnlocksSoft17PeekAndRedraw() {
        let suiteName = "cards.tests.props.more.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        let newly = props.syncFromAchievements([
            .dealerClear5,
            .practiceWinStreak5,
            .practiceWins20,
        ])
        #expect(Set(newly) == Set([.dealerSoft17Hit, .peekHole, .redrawOne]))
        #expect(props.canUse(.peekHole, in: .entertainment))
        #expect(props.canUse(.peekHole, in: .challenge) == false)
        #expect(props.canUse(.dealerSoft17Hit, in: .entertainment))
        #expect(props.canUse(.redrawOne, in: .challenge) == false)
    }

    // MARK: - v1.9 Sounds (P2)

    @Test func sixGameSoundsAreBundled() {
        for sound in GameSound.allCases {
            #expect(
                GameFeedback.isSoundBundled(sound),
                "Missing bundled sound: \(sound.rawValue) under Sounds/"
            )
        }
    }

    // MARK: - Helpers

    private func emptyProgress() -> AchievementProgressInput {
        AchievementProgressInput(
            mode: ModeProgress(),
            totalChipsWon: 0,
            dealerBankClearCount: 0,
            unlocked: []
        )
    }
}

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
