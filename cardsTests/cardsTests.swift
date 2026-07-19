//
//  cardsTests.swift
//  cardsTests
//
//  Created by 姬翔 on 2026/4/4.
//

import Testing
@testable import cards

/// 可复现随机序列，用于切牌点等单元测试。
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

struct cardsTests {

    @Test func deckSingleDeckHas52Cards() {
        let d = Deck(numberOfDecks: 1)
        #expect(d.cards.count == 52)
        #expect(d.totalCardCount == 52)
    }

    @Test(arguments: [2, 6])
    func deckMultiDeckCardCountMatchesShoe(decks: Int) {
        let d = Deck(numberOfDecks: decks)
        #expect(d.cards.count == decks * 52)
        #expect(d.totalCardCount == decks * 52)
    }

    @Test func deckDrawEmptiesShoe() {
        var d = Deck(numberOfDecks: 2)
        var rng = SeededRNG(state: 42)
        d.shuffle(using: &rng)
        var drawn = 0
        while d.draw() != nil { drawn += 1 }
        #expect(drawn == 2 * 52)
        #expect(d.dealtCount == 2 * 52)
        #expect(d.remainingCount == 0)
    }

    @Test func practiceModeDeckCountsMatchRoadmap() {
        #expect(PracticeMode.singleDeck.numberOfDecks == 1)
        #expect(PracticeMode.shoe2.numberOfDecks == 2)
        #expect(PracticeMode.shoe6.numberOfDecks == 6)
    }

    @Test func practiceModeLabelsUseChineseDeckNames() {
        #expect(PracticeMode.singleDeck.shortLabel == "一副牌")
        #expect(PracticeMode.shoe2.shortLabel == "两副牌")
        #expect(PracticeMode.shoe6.shortLabel == "六副牌")
        #expect(PracticeMode.singleDeck.pickerLabel == "一副牌")
    }

    @Test func cutPositionFallsWithinPenetrationRange() {
        var rng = SeededRNG(state: 7)
        for decks in [1, 2, 6] {
            var d = Deck(numberOfDecks: decks)
            d.shuffleAndCut(using: &rng)
            let total = d.totalCardCount
            let minCut = max(1, Int(Double(total) * Deck.cutPenetrationRange.lowerBound))
            let maxCut = max(minCut, Int(Double(total) * Deck.cutPenetrationRange.upperBound))
            #expect(d.cutPosition >= minCut)
            #expect(d.cutPosition <= maxCut)
        }
    }

    @Test func shuffleAndCutResetsDealtCountAndRefillsShoe() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 99)
        d.shuffleAndCut(using: &rng)
        let firstCut = d.cutPosition
        for _ in 0..<10 { _ = d.draw() }
        #expect(d.dealtCount == 10)
        #expect(d.remainingCount == 52 - 10)

        d.shuffleAndCut(using: &rng)
        #expect(d.dealtCount == 0)
        #expect(d.remainingCount == 52)
        #expect(d.cutPosition == firstCut || d.cutPosition >= 1)
    }

    @Test func needsReshuffleWhenDealtCountReachesCutPosition() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 123)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition
        #expect(d.needsReshuffleBeforeNextRound == false)

        for _ in 0..<cut {
            #expect(d.draw() != nil)
        }
        #expect(d.dealtCount == cut)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func needsReshuffleWhenRemainingBelowMinimumForRound() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 456)
        d.shuffleAndCut(using: &rng)
        while d.remainingCount > Deck.minimumCardsForRound {
            _ = d.draw()
        }
        #expect(d.remainingCount == Deck.minimumCardsForRound)

        _ = d.draw()
        #expect(d.remainingCount < Deck.minimumCardsForRound)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func pastCutWithFewerThanSevenCardsAllowsPlayOutRound() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 777)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition
        // 发到切牌点后再继续发，使剩余落在 4…6（尾牌局，不重洗）。
        let targetRemaining = 5
        let drawsNeeded = d.totalCardCount - targetRemaining
        for _ in 0..<drawsNeeded {
            #expect(d.draw() != nil)
        }
        #expect(d.remainingCount == targetRemaining)
        #expect(d.dealtCount >= cut)
        #expect(d.needsReshuffleBeforeNextRound == false)

        // 本局可继续发至最后一张。
        for _ in 0..<targetRemaining {
            #expect(d.draw() != nil)
        }
        #expect(d.remainingCount == 0)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func pastCutWithAtLeastSevenCardsNeedsReshuffle() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 888)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition
        for _ in 0..<cut {
            _ = d.draw()
        }
        #expect(d.remainingCount >= Deck.playOutThresholdWhenPastCut)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

  @Test(arguments: [1, 2, 6])
    func drawDealsExactlyExpectedCopiesPerCard(decks: Int) {
        var d = Deck(numberOfDecks: decks)
        var rng = SeededRNG(state: 2026)
        d.shuffleAndCut(using: &rng)
        var counts: [Card: Int] = [:]
        var drawn = 0
        while let card = d.draw() {
            counts[card, default: 0] += 1
            drawn += 1
        }
        #expect(drawn == decks * 52)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = Card(suit: suit, rank: rank)
                #expect(counts[card] == decks)
            }
        }
    }

    @Test func roundCanFinishAfterCrossingCutPosition() {
        var d = Deck(numberOfDecks: 1)
        var rng = SeededRNG(state: 123)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition

        for _ in 0..<cut {
            #expect(d.draw() != nil)
        }
        #expect(d.dealtCount == cut)
        #expect(d.needsReshuffleBeforeNextRound == true)

        // 已达切牌点：本局仍可继续发牌，重洗推迟到下一局开始前。
        let extraDraws = 3
        for _ in 0..<extraDraws {
            #expect(d.draw() != nil)
        }
        #expect(d.dealtCount == cut + extraDraws)
        #expect(d.needsReshuffleBeforeNextRound == true)
    }

    @Test func reshuffleAfterCutRestoresFullShoe() {
        var d = Deck(numberOfDecks: 6)
        var rng = SeededRNG(state: 314)
        d.shuffleAndCut(using: &rng)
        let cut = d.cutPosition
        for _ in 0..<cut { _ = d.draw() }
        #expect(d.needsReshuffleBeforeNextRound == true)
        #expect(d.remainingCount == d.totalCardCount - cut)

        d.shuffleAndCut(using: &rng)
        #expect(d.dealtCount == 0)
        #expect(d.remainingCount == 6 * 52)
        #expect(d.needsReshuffleBeforeNextRound == false)
    }
}
