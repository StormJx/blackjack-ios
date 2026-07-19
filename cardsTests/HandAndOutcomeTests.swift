//
//  HandAndOutcomeTests.swift
//  cardsTests
//
//  D13：Hand 计牌与停牌后胜负判定。
//

import Testing
@testable import cards

struct HandAndOutcomeTests {

    // MARK: - Hand 计牌

    @Test func hardTotalsWithoutAces() {
        let hand = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .hearts, rank: .seven),
        ])
        #expect(hand.bestValue == 17)
        #expect(hand.isBusted == false)
        #expect(hand.isNaturalBlackjack == false)
    }

    @Test func softAceCountsElevenWhenSafe() {
        let hand = Hand(cards: [
            Card(suit: .spades, rank: .ace),
            Card(suit: .hearts, rank: .six),
        ])
        #expect(hand.bestValue == 17)
    }

    @Test func aceFallsBackToOneToAvoidBust() {
        let hand = Hand(cards: [
            Card(suit: .spades, rank: .ace),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .clubs, rank: .five),
        ])
        #expect(hand.bestValue == 15)
        #expect(hand.isBusted == false)
    }

    @Test func naturalBlackjackIsTwoCardTwentyOne() {
        let natural = Hand(cards: [
            Card(suit: .spades, rank: .ace),
            Card(suit: .hearts, rank: .king),
        ])
        #expect(natural.bestValue == 21)
        #expect(natural.isNaturalBlackjack)

        let threeCardTwentyOne = Hand(cards: [
            Card(suit: .spades, rank: .seven),
            Card(suit: .hearts, rank: .seven),
            Card(suit: .clubs, rank: .seven),
        ])
        #expect(threeCardTwentyOne.bestValue == 21)
        #expect(threeCardTwentyOne.isNaturalBlackjack == false)
    }

    @Test func bustWhenOverTwentyOne() {
        let hand = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .two),
        ])
        #expect(hand.bestValue == 22)
        #expect(hand.isBusted)
    }

    // MARK: - 停牌后比点

    @Test func fromFinalPointsDealerBustIsPlayerWin() {
        #expect(RoundOutcome.fromFinalPoints(playerBest: 18, dealerBest: 22) == .playerWin)
    }

    @Test func fromFinalPointsComparesValues() {
        #expect(RoundOutcome.fromFinalPoints(playerBest: 20, dealerBest: 19) == .playerWin)
        #expect(RoundOutcome.fromFinalPoints(playerBest: 18, dealerBest: 19) == .playerLose)
        #expect(RoundOutcome.fromFinalPoints(playerBest: 19, dealerBest: 19) == .push)
    }

    @Test func outcomeStatusIconsAreStable() {
        #expect(RoundOutcome.playerWin.statusIconName == "checkmark.circle.fill")
        #expect(RoundOutcome.playerBlackjack.statusIconName == "checkmark.circle.fill")
        #expect(RoundOutcome.playerLose.statusIconName == "xmark.circle.fill")
        #expect(RoundOutcome.push.statusIconName == "equal.circle.fill")
    }
}
