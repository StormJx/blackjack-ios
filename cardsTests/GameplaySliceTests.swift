//
//  GameplaySliceTests.swift
//  cardsTests
//
//  分牌规则、第二注结算、庄家池比例、每日目标。
//

import Foundation
import Testing
@testable import cards

@MainActor
struct GameplaySliceTests {

    @Test func samePointValueAllowsTensAndRejectsOffRank() {
        #expect(SplitRules.samePointValue(.ten, .king))
        #expect(SplitRules.samePointValue(.ace, .ace))
        #expect(SplitRules.samePointValue(.nine, .ten) == false)
        #expect(SplitRules.isAcePair(.ace, .ace))
        #expect(SplitRules.isAcePair(.ace, .king) == false)
    }

    @Test func dealerBankFractionClampsToFullAndEmpty() {
        #expect(TableHUD.dealerBankFraction(remaining: 500, capacity: 1000) == 0.5)
        #expect(TableHUD.dealerBankFraction(remaining: 1500, capacity: 1000) == 1)
        #expect(TableHUD.dealerBankFraction(remaining: 0, capacity: 1000) == 0)
        #expect(TableHUD.dealerBankFraction(remaining: 100, capacity: 0) == 0)
    }

    @Test func dailyGoalAwardsBadgeWithoutResettingStreakAcrossAGap() {
        let defaults = UserDefaults(suiteName: "cards.tests.daily.\(UUID().uuidString)")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        let day2 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 2))!
        let day4 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 4))!
        let store = DailyGoalStore(defaults: defaults, calendar: calendar, now: day1)

        var notice: String?
        for _ in 0..<2 {
            notice = store.record(playStyle: .entertainment, outcome: .playerWin, playerBusted: false, now: day1)
            #expect(notice == nil)
        }
        notice = store.record(playStyle: .entertainment, outcome: .playerWin, playerBusted: false, now: day1)
        #expect(notice != nil)
        #expect(store.snapshot.streak == 1)
        #expect(store.snapshot.entertainmentWins == 3)

        for _ in 0..<3 {
            _ = store.record(playStyle: .entertainment, outcome: .playerWin, playerBusted: false, now: day2)
        }
        #expect(store.snapshot.streak == 2)

        for _ in 0..<3 {
            _ = store.record(playStyle: .challenge, outcome: .playerWin, playerBusted: false, now: day4)
        }
        #expect(store.snapshot.entertainmentWins == 0)
        #expect(store.snapshot.cleanHands == 3)
        #expect(store.snapshot.streak == 0)
        _ = store.record(playStyle: .challenge, outcome: .playerLose, playerBusted: false, now: day4)
        notice = store.record(playStyle: .challenge, outcome: .playerLose, playerBusted: false, now: day4)
        #expect(notice != nil)
        #expect(store.snapshot.cleanHands == 5)
        #expect(store.snapshot.streak == 1)
    }
}

@MainActor
struct SplitHandTests {

    @Test func pairSplitsOnceAndAceSplitIsNotNaturalBlackjack() async {
        let game = makeGame()
        game.preparePlayerTurnForTesting(
            player: [Card(suit: .spades, rank: .eight), Card(suit: .hearts, rank: .eight)],
            dealer: [Card(suit: .clubs, rank: .six), Card(suit: .diamonds, rank: .ten)]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .hearts, rank: .king)
        ])

        #expect(game.canOfferSplit)
        await game.split()
        #expect(game.canOfferSplit == false)
        #expect(game.canSurrenderHand == false)
        #expect(game.canDoubleDownHand)
        #expect(game.phase == .playerTurn)
        await game.stand()
        #expect(game.phase == .playerTurn)
        #expect(game.splitFirstHand.count == 2)
        #expect(game.canOfferSplit == false)
        await game.stand()
        #expect(game.phase == .finished)
        #expect(game.splitHandOutcomes == [.playerWin, .playerWin])
        #expect(game.lastOutcome == .playerWin)
        #expect(game.makeRoundSnapshot(wasAllInBet: false)?.playerNaturalBlackjack == false)

        let aces = makeGame()
        aces.preparePlayerTurnForTesting(
            player: [Card(suit: .spades, rank: .ace), Card(suit: .hearts, rank: .ace)],
            dealer: [Card(suit: .clubs, rank: .ten), Card(suit: .diamonds, rank: .nine)]
        )
        aces.replaceRemainingShoeForTesting([
            Card(suit: .clubs, rank: .king),
            Card(suit: .diamonds, rank: .five)
        ])
        await aces.split()
        #expect(aces.phase == .finished)
        #expect(aces.splitHandOutcomes == [.playerWin, .playerLose])
        #expect(aces.lastOutcome == .push)
        #expect(aces.makeRoundSnapshot(wasAllInBet: false)?.playerNaturalBlackjack == false)
    }

    @Test func unmatchedRanksCannotSplit() {
        let game = makeGame()
        game.preparePlayerTurnForTesting(
            player: [Card(suit: .spades, rank: .nine), Card(suit: .hearts, rank: .ten)],
            dealer: [Card(suit: .clubs, rank: .six), Card(suit: .diamonds, rank: .ten)]
        )
        #expect(game.canOfferSplit == false)
    }

    private func makeGame() -> BlackjackGame {
        BlackjackGame(
            practiceMode: .singleDeck,
            cutCardMode: .off,
            timing: InstantGameTiming(),
            feedback: SilentGameFeedback()
        )
    }
}

@MainActor
struct SplitBankTests {

    @Test func splitRequiresSecondBetAndSettlesEachHand() {
        let defaults = UserDefaults(suiteName: "cards.tests.splitBank.\(UUID().uuidString)")!
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        #expect(bank.beginSplit())
        #expect(bank.balance == 800)
        #expect(bank.splitSecondBet == 100)
        #expect(bank.beginSplit() == false)

        let result = bank.settleSplit(first: .playerWin, second: .playerLose)
        #expect(result?.netChange == 0)
        #expect(result?.betAmount == 200)
        #expect(bank.balance == 1000)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.splitSecondBet == 0)
    }

    @Test func allInAndShortBalanceCannotSplit() {
        let defaults = UserDefaults(suiteName: "cards.tests.splitAllIn.\(UUID().uuidString)")!
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(bank.balance))
        #expect(bank.canBeginSplit == false)
        #expect(bank.beginSplit() == false)

        let short = ChipBank(defaults: UserDefaults(suiteName: "cards.tests.splitShort.\(UUID().uuidString)")!)
        #expect(short.placeBet(ChipRules.startingBalance - 50))
        #expect(short.canBeginSplit == false)
    }

    @Test func interruptedSplitRefundsBothStakes() {
        let suite = "cards.tests.splitInterrupt.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        #expect(bank.beginSplit())
        let restored = ChipBank(defaults: defaults)
        #expect(restored.balance == ChipRules.startingBalance)
        #expect(restored.splitSecondBet == 0)
        #expect(restored.didRestoreAfterInterrupt)
    }
}
