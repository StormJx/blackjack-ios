//
//  SessionCoordinatorTests.swift
//  cardsTests
//
//  A1：SessionCoordinator 局末编排单测。
//

import Foundation
import Testing
@testable import cards

@MainActor
struct SessionCoordinatorTests {

    // MARK: - 闯关赢局记账

    @Test func challengeWinRecordsChipsAndSyncsProgress() {
        ActiveTableLimits.apply(.standard)
        defer { ActiveTableLimits.apply(.standard) }
        let harness = Harness(playStyle: .challenge, dealerStartingBank: 2000)

        #expect(harness.chipBank.placeBet(100))
        let snapshot = Self.winSnapshot()
        let result = harness.coordinator.finishRound(
            outcome: .playerWin,
            insuranceWon: false,
            makeSnapshot: { _ in snapshot }
        )

        #expect(result.settlement?.netChange == 100)
        #expect(result.shouldPulseBalance)
        #expect(result.recordedOutcome == .playerWin)
        #expect(harness.statsStore.totalChipsWon == 100)
        #expect(harness.statsStore.challenge.wins == 1)
        #expect(harness.statsStore.challenge.rounds == 1)
        #expect(harness.chipBank.sessionRoundsCompleted == 1)
        // 累计赢未达升关门槛；关卡仍为 1，但 sync 路径已跑通。
        #expect(harness.challengeProgress.unlockedLevel == 1)
        #expect(harness.statsStore.dealerBankClearCount == 0)
    }

    @Test func challengeLargeWinCanLevelUpAndUnlockCardBack() {
        ActiveTableLimits.apply(.standard)
        let harness = Harness(playStyle: .challenge, dealerStartingBank: 2000)
        // 预置累计赢，使本局再赢后跨过第二关门槛（累计赢 ≥2000）。
        harness.statsStore.recordChipSettlement(netChange: 1950)

        #expect(harness.chipBank.placeBet(100))
        let result = harness.coordinator.finishRound(
            outcome: .playerWin,
            insuranceWon: false,
            makeSnapshot: { _ in Self.winSnapshot() }
        )

        #expect(harness.statsStore.totalChipsWon >= 2000)
        #expect(harness.challengeProgress.unlockedLevel >= 2)
        #expect(harness.cosmeticsStore.owns(.emeraldLattice))
        #expect(
            result.unlockNotices.contains(where: { $0.contains("卡背") || $0.contains("Card back") })
            || harness.cosmeticsStore.owns(.emeraldLattice)
        )
    }

    // MARK: - 娱乐打穿不计入闯关

    @Test func entertainmentDealerClearDoesNotTouchChallengeAchievements() {
        ActiveTableLimits.apply(.standard)
        let harness = Harness(
            playStyle: .entertainment,
            startingBalance: 1000,
            dealerStartingBank: 100
        )
        let challengeClearsBefore = harness.statsStore.dealerBankClearCount
        let challengeLevelBefore = harness.challengeProgress.unlockedLevel

        #expect(harness.chipBank.placeBet(100))
        let result = harness.coordinator.finishRound(
            outcome: .playerWin,
            insuranceWon: false,
            makeSnapshot: { _ in Self.winSnapshot() }
        )

        #expect(harness.chipBank.sessionEndReason == .dealerBroke)
        #expect(harness.entertainmentProgress.dealerClearCount == 1)
        #expect(harness.entertainmentProgress.unlockedLevel >= 2)
        #expect(harness.statsStore.dealerBankClearCount == challengeClearsBefore)
        #expect(harness.challengeProgress.unlockedLevel == challengeLevelBefore)
        #expect(harness.statsStore.challenge.wins == 0)
        #expect(harness.statsStore.practice.wins == 1)
        #expect(
            result.unlockNotices.contains(L10n.t("entertainment.stage.2.title"))
            || result.unlockNotices.contains(L10n.t("unlock.entertainmentClear"))
        )
    }

    // MARK: - 保险赔付净盈亏

    @Test func insuranceWinWithDealerBlackjackNetsZeroViaCoordinator() {
        ActiveTableLimits.apply(.standard)
        let harness = Harness(playStyle: .challenge, dealerStartingBank: 2000)

        #expect(harness.chipBank.placeBet(100))
        #expect(harness.chipBank.placeInsurance())
        #expect(harness.chipBank.activeInsurance == 50)
        #expect(harness.chipBank.balance == 850)

        let result = harness.coordinator.finishRound(
            outcome: .playerLose,
            insuranceWon: true,
            makeSnapshot: { _ in
                RoundSnapshot(
                    outcome: .playerLose,
                    playerCardCount: 2,
                    playerBest: 18,
                    dealerBest: 21,
                    playerBusted: false,
                    dealerBusted: false,
                    playerNaturalBlackjack: false
                )
            }
        )

        #expect(result.settlement?.netChange == 0)
        #expect(result.settlement?.insuranceNetChange == 100)
        #expect(harness.chipBank.balance == 1000)
        #expect(harness.statsStore.totalChipsWon == 0)
        #expect(harness.statsStore.totalChipsLost == 0)
        #expect(harness.chipBank.activeBet == 0)
        #expect(harness.chipBank.activeInsurance == 0)
    }

    // MARK: - 中途退出（无 outcome）

    @Test func abandonWithoutOutcomeRefundsAndDoesNotRecordRound() {
        ActiveTableLimits.apply(.standard)
        let harness = Harness(playStyle: .challenge, dealerStartingBank: 2000)

        #expect(harness.chipBank.placeBet(200))
        #expect(harness.chipBank.placeInsurance())
        #expect(harness.chipBank.activeBet == 200)
        #expect(harness.chipBank.activeInsurance == 100)
        #expect(harness.chipBank.balance == 700)

        let result = harness.coordinator.finishRound(
            outcome: nil,
            insuranceWon: false,
            makeSnapshot: { _ in nil }
        )

        #expect(result.recordedOutcome == nil)
        #expect(result.settlement == nil)
        #expect(result.unlockNotices.isEmpty)
        #expect(result.shouldPulseBalance == false)
        #expect(harness.chipBank.activeBet == 0)
        #expect(harness.chipBank.activeInsurance == 0)
        #expect(harness.chipBank.balance == 1000)
        #expect(harness.chipBank.sessionRoundsCompleted == 0)
        #expect(harness.statsStore.challenge.rounds == 0)
    }

    // MARK: - Helpers

    private static func winSnapshot() -> RoundSnapshot {
        RoundSnapshot(
            outcome: .playerWin,
            playerCardCount: 2,
            playerBest: 20,
            dealerBest: 18,
            playerBusted: false,
            dealerBusted: false,
            playerNaturalBlackjack: false
        )
    }

    @MainActor
    private final class Harness {
        let statsStore: StatsStore
        let propStore: PropStore
        let challengeProgress: ChallengeProgress
        let entertainmentProgress: EntertainmentProgress
        let cosmeticsStore: CosmeticsStore
        let chipBank: ChipBank
        let coordinator: SessionCoordinator

        init(
            playStyle: PlayStyle,
            startingBalance: Int = ChipRules.startingBalance,
            dealerStartingBank: Int
        ) {
            let suiteName = "cards.tests.sessionCoordinator.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)

            statsStore = StatsStore(defaults: defaults)
            propStore = PropStore(defaults: defaults)
            challengeProgress = ChallengeProgress(defaults: defaults)
            entertainmentProgress = EntertainmentProgress(defaults: defaults)
            cosmeticsStore = CosmeticsStore(defaults: defaults)
            chipBank = ChipBank(
                defaults: defaults,
                storageKey: "test.balance",
                dealerBankKey: "test.dealerBank",
                activeBetKey: "test.activeBet",
                activeInsuranceKey: "test.activeInsurance",
                sessionRoundsKey: "test.sessionRounds",
                startingBalance: startingBalance,
                dealerStartingBank: dealerStartingBank,
                forceFreshSession: true
            )
            coordinator = SessionCoordinator(
                playStyle: playStyle,
                chipBank: chipBank,
                statsStore: statsStore,
                propStore: propStore,
                challengeProgress: challengeProgress,
                entertainmentProgress: entertainmentProgress,
                cosmeticsStore: cosmeticsStore
            )
        }
    }
}
