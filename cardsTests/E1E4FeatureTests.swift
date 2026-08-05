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

    @Test func fastStatsSurrenderCountsAsLoss() {
        var stats = FastSessionStats()
        stats.record(.playerWin)
        stats.record(.playerSurrender)
        #expect(stats.wins == 1)
        #expect(stats.losses == 1)
        #expect(stats.currentWinStreak == 0)
    }

    // MARK: - E2 AppSettings + Deck cut

    @Test @MainActor
    func appSettingsPersistsAndReloads() {
        let suiteName = "cards.tests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.defaultPracticeMode = .shoe6
        settings.cutCardMode = .off
        settings.preDealAllInUnlockRounds = 3
        settings.soundEnabled = false
        settings.hapticsEnabled = false
        settings.confirmMidHandAllIn = false

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.defaultPracticeMode == .shoe6)
        #expect(reloaded.cutCardMode == .off)
        #expect(reloaded.preDealAllInUnlockRounds == 3)
        #expect(reloaded.soundEnabled == false)
        #expect(reloaded.hapticsEnabled == false)
        #expect(reloaded.confirmMidHandAllIn == false)
        #expect(reloaded.tableLimitPreset == .standard)
        #expect(reloaded.tableLimitsSummary.contains("100"))

        settings.tableLimitPreset = .light
        settings.cutCardMode = .ceremonial
        let reloadedLimits = AppSettings(defaults: defaults)
        #expect(reloadedLimits.tableLimitPreset == .light)
        #expect(reloadedLimits.tableLimitsSummary.contains("50"))
        #expect(reloadedLimits.cutCardMode == .ceremonial)
    }

    @Test @MainActor
    func appSettingsMigratesLegacyCutCardBool() {
        let suiteName = "cards.tests.settings.cut.migrate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: "appSettings.cutCardEnabled")
        let offSettings = AppSettings(defaults: defaults)
        #expect(offSettings.cutCardMode == .off)

        let suiteName2 = "cards.tests.settings.cut.migrate2.\(UUID().uuidString)"
        let defaults2 = UserDefaults(suiteName: suiteName2)!
        defer { defaults2.removePersistentDomain(forName: suiteName2) }
        defaults2.set(true, forKey: "appSettings.cutCardEnabled")
        let realSettings = AppSettings(defaults: defaults2)
        #expect(realSettings.cutCardMode == .real)
    }

    /// UX9：会话级设置统一提示文案（牌副 / 切牌 / 桌限 / 全下解锁）。
    @Test func ux9SessionLockedSettingsHintIsUnified() {
        let hint = AppSettings.sessionLockedSettingsHint
        #expect(hint == AppSettings.sessionLockedSettingsChangeFlash)
        #expect(hint.contains("对局中修改不生效"))
        #expect(hint.contains("返回主页后新开局生效"))
        #expect(!hint.contains("对下一局生效"))
    }

    @Test func deckCutDisabledRequiresReshuffleAfterAnyDeal() {
        var d = Deck(numberOfDecks: 1, cutCardMode: .off)
        var rng = SeededRNG(state: 11)
        d.shuffleAndCut(using: &rng)
        #expect(d.needsReshuffleBeforeNextRound == false)
        _ = d.draw()
        #expect(d.remainingCount < d.totalCardCount)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func deckCeremonialIgnoresCutPositionUntilCardsRunLow() {
        var d = Deck(numberOfDecks: 1, cutCardMode: .ceremonial)
        var rng = SeededRNG(state: 33)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition
        for _ in 0..<cut { _ = d.draw() }
        #expect(d.dealtCount >= cut)
        #expect(d.remainingCount >= Deck.minimumCardsForRound)
        #expect(d.needsReshuffleBeforeNextRound == false)

        while d.remainingCount >= Deck.minimumCardsForRound {
            _ = d.draw()
        }
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func deckCutEnabledStillHonorsPenetration() {
        var d = Deck(numberOfDecks: 1, cutCardMode: .real)
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

    @Test func challengeAndEntertainmentStageBankSummariesForStats() {
        #expect(ChallengeRules.stageBankSummary(level: 1) == "第一关：你 1000 · 庄家 2000")
        #expect(ChallengeRules.stageBankSummary(level: 3) == "第三关：你 2500 · 庄家 7000")
        #expect(EntertainmentRules.stageBankSummary(level: 2) == "娱乐二阶：你 2000 · 庄家 5000")
        #expect(EntertainmentRules.stage(level: 2).tableLimitsSummary.contains("200 / 400 / 800"))

        let entHint = EntertainmentRules.progressHint(
            unlockedLevel: 1,
            dealerClears: 0,
            totalChipsWon: 500
        )
        #expect(entHint.contains("娱乐一阶"))
        #expect(entHint.contains("1500"))
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
        var deck = Deck(numberOfDecks: 1, cutCardMode: .real)
        var rng = SeededRNG(state: 42)
        deck.shuffleAndCut(using: &rng)
        let before = deck.remainingCount
        guard let card = deck.draw() else {
            Issue.record("expected a card")
            return
        }
        #expect(deck.remainingCount == before - 1)
        let dealtAfterDraw = deck.dealtCount
        deck.returnCardToShoe(card, using: &rng)
        #expect(deck.remainingCount == before)
        #expect(deck.dealtCount == dealtAfterDraw - 1)
    }

    @Test func returnThenDrawKeepsDealtCountAndAvoidsSameCard() {
        var deck = Deck(numberOfDecks: 1, cutCardMode: .real)
        var rng = SeededRNG(state: 77)
        deck.shuffleAndCut(using: &rng)
        guard let card = deck.draw() else {
            Issue.record("expected a card")
            return
        }
        let dealtBeforeSwap = deck.dealtCount
        let remainingBeforeSwap = deck.remainingCount
        deck.returnCardToShoe(card, using: &rng)
        #expect(deck.dealtCount == dealtBeforeSwap - 1)
        #expect(deck.remainingCount == remainingBeforeSwap + 1)

        guard let replacement = deck.draw() else {
            Issue.record("expected replacement")
            return
        }
        #expect(deck.dealtCount == dealtBeforeSwap)
        #expect(deck.remainingCount == remainingBeforeSwap)
        #expect(replacement != card)
    }

    @Test func returnCardToEmptyShoeAllowsSameCardRedraw() {
        var deck = Deck(numberOfDecks: 1, cutCardMode: .real)
        var rng = SeededRNG(state: 5)
        deck.shuffleAndCut(using: &rng)
        var last: Card?
        while deck.remainingCount > 0 {
            last = deck.draw()
        }
        guard let card = last else {
            Issue.record("expected last card")
            return
        }
        #expect(deck.remainingCount == 0)
        deck.returnCardToShoe(card, using: &rng)
        #expect(deck.remainingCount == 1)
        #expect(deck.draw() == card)
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
    func propStoreUnlocksSoft17PeekRedrawAndReshuffle() {
        let suiteName = "cards.tests.props.more.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        let newly = props.syncFromAchievements([
            .dealerClear5,
            .practiceWinStreak5,
            .practiceWins20,
            .practiceWins50,
        ])
        #expect(Set(newly) == Set([
            .dealerSoft17Hit,
            .peekHole,
            .redrawOne,
            .reshuffleDealerCard,
        ]))
        #expect(props.canUse(.peekHole, in: .entertainment))
        #expect(props.canUse(.peekHole, in: .challenge) == false)
        #expect(props.canUse(.dealerSoft17Hit, in: .entertainment))
        #expect(props.canUse(.redrawOne, in: .challenge) == false)
        #expect(props.canUse(.reshuffleDealerCard, in: .entertainment))
        #expect(props.canUse(.reshuffleDealerCard, in: .challenge) == false)
        #expect(PropID.reshuffleDealerCard.unlockAchievement == .practiceWins50)
    }

    @Test @MainActor
    func reshuffleDealerCardBlockedOutsidePlayerTurn() async {
        let game = BlackjackGame(practiceMode: .singleDeck, cutCardMode: .real)
        #expect(game.canReshuffleDealerCard == false)
        var rng = SeededRNG(state: 3)
        #expect(await game.reshuffleDealerCard(using: &rng) == false)
        #expect(game.hasReshuffledDealerThisRound == false)
    }

    @Test @MainActor
    func reshuffleDealerCardReplacesOneDealerCardOncePerRound() async {
        let game = BlackjackGame(practiceMode: .singleDeck, cutCardMode: .real)
        let player = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .seven),
        ]
        let dealer = [
            Card(suit: .spades, rank: .nine),
            Card(suit: .diamonds, rank: .four),
        ]
        game.preparePlayerTurnForTesting(player: player, dealer: dealer)

        #expect(game.phase == .playerTurn)
        #expect(game.canReshuffleDealerCard)
        let beforeRemaining = game.remainingCardCount
        let beforeDealer = game.dealerCards

        var rng = SeededRNG(state: 99)
        let ok = await game.reshuffleDealerCard(using: &rng)
        #expect(ok)
        #expect(game.dealerCards.count == beforeDealer.count)
        #expect(game.remainingCardCount == beforeRemaining)
        #expect(game.dealerCards != beforeDealer)
        #expect(game.hasReshuffledDealerThisRound)
        #expect(game.canReshuffleDealerCard == false)
        #expect(game.propActionHint == "已换庄家一张")
        #expect(game.reshufflePulseIndex != nil)

        let afterFirst = game.dealerCards
        var rng2 = SeededRNG(state: 100)
        #expect(await game.reshuffleDealerCard(using: &rng2) == false)
        #expect(game.dealerCards == afterFirst)
    }

    @Test @MainActor
    func reshuffleDealerCardBlockedWhilePeeking() async {
        let game = BlackjackGame(practiceMode: .singleDeck, cutCardMode: .real)
        let player = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .eight),
        ]
        let dealer = [
            Card(suit: .spades, rank: .king),
            Card(suit: .diamonds, rank: .six),
        ]
        game.preparePlayerTurnForTesting(player: player, dealer: dealer)
        #expect(game.canReshuffleDealerCard)

        let peek = Task { await game.peekHoleCard() }
        // 窥视启动后短等，确认窥视中门控。
        try? await Task.sleep(nanoseconds: 50_000_000)
        if game.isPeekingHoleCard {
            #expect(game.canReshuffleDealerCard == false)
            var rng = SeededRNG(state: 7)
            #expect(await game.reshuffleDealerCard(using: &rng) == false)
            #expect(game.hasReshuffledDealerThisRound == false)
        }
        await peek.value
        #expect(game.isPeekingHoleCard == false)
        #expect(game.canReshuffleDealerCard)
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

    // MARK: - UX1–UX8

    @Test func welcomeSubtitlesAreShortOneLiners() {
        // 欢迎页布局预算按中文源文案；英文本地有独立较长译文。
        #expect(L10n.t("playStyle.challenge.subtitle", language: "zh-Hans").count <= 24)
        #expect(L10n.t("playStyle.entertainment.subtitle", language: "zh-Hans").count <= 24)
        #expect(!L10n.t("playStyle.challenge.subtitle", language: "zh-Hans").contains("三档"))
        // 当前语言下不得回落到 key 本身（L10n 缺译回退 zh-Hans / 或已有 en）。
        #expect(PlayStyle.challenge.welcomeSubtitle != "playStyle.challenge.subtitle")
        #expect(PlayStyle.entertainment.welcomeSubtitle != "playStyle.entertainment.subtitle")
    }

    @Test func l10nFallsBackToSimplifiedChineseWhenEnglishMissing() {
        // en.lproj 仅有欢迎页少量 key；缺译必须回退中文，不能显示 key。
        #expect(PracticeMode.singleDeck.shortLabel == "一副牌")
        #expect(AppSettings.sessionLockedSettingsHint.contains("对局中修改不生效"))
        #expect(AchievementID.practiceWins20.title.hasPrefix("娱乐"))
        // 已有 en 的欢迎文案在英文本地仍可为英文（不强制中文）。
        #expect(L10n.t("welcome.appTitle", language: "en") == "Blackjack")
        #expect(L10n.t("welcome.appTitle", language: "zh-Hans") == "二十一点")
    }

    @Test func entertainmentAchievementTitlesUseEntertainmentWording() {
        #expect(AchievementID.practiceWinStreak5.title.hasPrefix("娱乐"))
        #expect(AchievementID.practiceWins20.title.hasPrefix("娱乐"))
        #expect(AchievementID.practiceFiveCard.title.hasPrefix("娱乐"))
        #expect(AchievementID.practiceNaturalBJ.title.hasPrefix("娱乐"))
        #expect(!AchievementID.practiceWins50.title.contains("练习"))
    }

    @Test func challengeUnlockedPropsShowCrossModeHint() {
        #expect(PropID.midHandAllIn.unlocksViaChallenge)
        #expect(PropID.dealerSoft17Hit.unlocksViaChallenge)
        #expect(PropID.peekHole.unlocksViaChallenge == false)
    }

    @Test @MainActor
    func propGameplayGuideAcknowledgedOnce() {
        let suiteName = "cards.tests.props.guide.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let props = PropStore(defaults: defaults)
        #expect(props.needsGameplayPropsGuide == false)
        #expect(props.unlock(.peekHole))
        #expect(props.needsGameplayPropsGuide)
        props.acknowledgeGameplayPropsGuide()
        #expect(props.needsGameplayPropsGuide == false)

        let reloaded = PropStore(defaults: defaults)
        #expect(reloaded.owns(.peekHole))
        #expect(reloaded.needsGameplayPropsGuide == false)
    }

    @Test @MainActor
    func confirmMidHandAllInDefaultsToTrue() {
        let suiteName = "cards.tests.settings.allin.confirm.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.confirmMidHandAllIn)
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
