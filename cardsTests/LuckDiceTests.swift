//
//  LuckDiceTests.swift
//  cardsTests
//
//  骰子门槛、好运局数，以及免爆换牌。
//

import Foundation
import Testing
@testable import cards

struct LuckDiceTests {

    @Test func luckyThresholdsScaleWithDiceCount() {
        #expect(LuckDiceRules.isLucky(total: 5, diceCount: 1))
        #expect(LuckDiceRules.isLucky(total: 4, diceCount: 1) == false)
        #expect(LuckDiceRules.isLucky(total: 9, diceCount: 2))
        #expect(LuckDiceRules.isLucky(total: 8, diceCount: 2) == false)
        #expect(LuckDiceRules.isLucky(total: 13, diceCount: 3))
        #expect(LuckDiceRules.isLucky(total: 12, diceCount: 3) == false)
    }

    @Test func rescueSwapsABustForTheNextSafeCard() {
        var deck = Deck(numberOfDecks: 1, cutCardMode: .off)
        let current = [
            Card(suit: .spades, rank: .ten),
            Card(suit: .hearts, rank: .six)
        ]
        let king = Card(suit: .clubs, rank: .king)
        let five = Card(suit: .diamonds, rank: .five)
        deck.installOrderedShoeForTesting([king, five])
        let drawn = deck.draw()
        let rescued = deck.rescueBustingPlayerCard(drawn!, current: current)
        #expect(rescued.didRescue)
        #expect(rescued.card == five)
        #expect(deck.draw() == king)

        var bothBust = Deck(numberOfDecks: 1, cutCardMode: .off)
        let queen = Card(suit: .hearts, rank: .queen)
        bothBust.installOrderedShoeForTesting([king, queen])
        let first = bothBust.draw()
        let kept = bothBust.rescueBustingPlayerCard(first!, current: current)
        #expect(kept.didRescue == false)
        #expect(kept.card == king)
        #expect(bothBust.draw() == queen)
    }
}

@MainActor
struct LuckDiceStoreTests {

    @Test func highRollRefreshesBuffAndLowRollDoesNotClearIt() {
        let defaults = UserDefaults(suiteName: "cards.tests.luck.\(UUID().uuidString)")!
        let store = LuckDiceStore(defaults: defaults)
        store.apply(faces: [6])
        #expect(store.state.roundsRemaining == 3)
        #expect(store.state.lastRollIsLucky)

        store.apply(faces: [1, 2])
        #expect(store.state.roundsRemaining == 3)
        #expect(store.state.lastRollIsLucky == false)
        #expect(store.state.total == 3)

        store.consumeRound()
        #expect(store.state.roundsRemaining == 2)
        let reloaded = LuckDiceStore(defaults: defaults)
        #expect(reloaded.state.roundsRemaining == 2)
    }

    @Test func luckRescueSavesOneBustingHit() async {
        let game = BlackjackGame(
            practiceMode: .singleDeck,
            cutCardMode: .off,
            timing: InstantGameTiming(),
            feedback: SilentGameFeedback()
        )
        game.luckRescueEnabled = true
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .six)
            ],
            dealer: [
                Card(suit: .clubs, rank: .nine),
                Card(suit: .diamonds, rank: .seven)
            ]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .clubs, rank: .king),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .hearts, rank: .two)
        ])
        await game.hit()
        #expect(game.playerCards.map(\.rank) == [.ten, .six, .five])
        #expect(game.playerBustedAllHands == false)
    }
}
