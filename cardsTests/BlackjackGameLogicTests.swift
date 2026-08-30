//
//  BlackjackGameLogicTests.swift
//  cardsTests
//
//  Q2：天然 BJ / hit-stand / 庄家软 17 / 牌尽 fallback 确定性单测。
//

import Testing
@testable import cards

@MainActor
struct BlackjackGameLogicTests {

    @Test func naturalBlackjackResolvesImmediately() async {
        let game = makeTestGame()
        // 发牌顺序：玩家、庄家、玩家、庄家
        game.installOrderedShoeForTesting([
            Card(suit: .spades, rank: .ace),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .five),
        ])
        await game.startNewRound()
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerBlackjack)
        #expect(game.playerCards.count == 2)
        #expect(Hand(cards: game.playerCards).isNaturalBlackjack)
    }

    @Test func hitBustsWhenDrawingOverTwentyOne() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .nine),
            ],
            dealer: [
                Card(suit: .clubs, rank: .seven),
                Card(suit: .diamonds, rank: .six),
            ]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .spades, rank: .king),
        ])
        await game.hit()
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerLose)
        #expect(game.playerCards.count == 3)
        #expect(Hand(cards: game.playerCards).isBusted)
    }

    @Test func standLeavesDealerSoftSeventeenByDefault() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .nine),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ace),
                Card(suit: .diamonds, rank: .six),
            ]
        )
        // 若误要牌会抽到这张；默认软 17 停则不应抽。
        game.replaceRemainingShoeForTesting([
            Card(suit: .hearts, rank: .two),
        ])
        #expect(Hand(cards: game.dealerCards).isSoftSeventeen)
        await game.stand()
        #expect(game.phase == .finished)
        #expect(game.dealerCards.count == 2)
        #expect(game.lastOutcome == .playerWin)
    }

    @Test func dealerSoftSeventeenHitsWhenPropActivated() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .eight),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ace),
                Card(suit: .diamonds, rank: .six),
            ]
        )
        #expect(game.activateDealerSoft17Hit())
        game.replaceRemainingShoeForTesting([
            Card(suit: .hearts, rank: .two),
        ])
        await game.stand()
        #expect(game.phase == .finished)
        #expect(game.dealerCards.count == 3)
        #expect(Hand(cards: game.dealerCards).bestValue == 19)
        #expect(game.lastOutcome == .playerLose)
    }

    @Test func hitWithEmptyShoeFallsThroughToDealerTurn() async {
        let game = makeTestGame()
        game.preparePlayerTurnWithEmptyShoeForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .eight),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ten),
                Card(suit: .diamonds, rank: .seven),
            ]
        )
        #expect(game.remainingCardCount == 0)
        await game.hit()
        #expect(game.phase == .finished)
        #expect(game.playerCards.count == 2)
        #expect(game.lastOutcome == .playerWin)
    }

    @Test func doubleDownTakesOneCardThenDealerTurn() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .five),
                Card(suit: .hearts, rank: .six),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ten),
                Card(suit: .diamonds, rank: .seven),
            ]
        )
        #expect(game.canDoubleDownHand)
        game.replaceRemainingShoeForTesting([
            Card(suit: .spades, rank: .ten),
        ])
        await game.doubleDown()
        #expect(game.phase == .finished)
        #expect(game.playerCards.count == 3)
        #expect(Hand(cards: game.playerCards).bestValue == 21)
        #expect(game.lastOutcome == .playerWin)
    }

    @Test func doubleDownBustsResolvesImmediately() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .nine),
            ],
            dealer: [
                Card(suit: .clubs, rank: .seven),
                Card(suit: .diamonds, rank: .six),
            ]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .spades, rank: .king),
        ])
        await game.doubleDown()
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerLose)
        #expect(game.playerCards.count == 3)
        #expect(Hand(cards: game.playerCards).isBusted)
    }

    @Test func doubleDownUnavailableAfterHit() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .five),
                Card(suit: .hearts, rank: .six),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ten),
                Card(suit: .diamonds, rank: .seven),
            ]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .diamonds, rank: .two),
            Card(suit: .spades, rank: .three),
        ])
        await game.hit()
        #expect(game.phase == .playerTurn)
        #expect(game.playerCards.count == 3)
        #expect(game.canDoubleDownHand == false)
        #expect(game.doubleDownHandDisabledReason == L10n.t("disabled.doubleOnlyTwoCards"))
    }

    @Test func dealerAceOffersInsuranceThenPeekNoBlackjack() async {
        let game = makeTestGame()
        // 发牌：玩家、庄家明 A、玩家、庄家暗牌（非 BJ）
        game.installOrderedShoeForTesting([
            Card(suit: .spades, rank: .ten),
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine),
            Card(suit: .clubs, rank: .five),
        ])
        await game.startNewRound()
        #expect(game.phase == .insuranceOffer)
        #expect(game.dealerUpcardIsAce)
        #expect(game.canResolveInsuranceOffer)
        await game.resolveInsuranceDecision(didBuyInsurance: false)
        #expect(game.phase == .playerTurn)
        #expect(game.lastInsuranceWon == false)
        #expect(game.hideDealerHoleCard)
        #expect(game.canPeekHoleCard)
    }

    @Test func dealerAcePeekBlackjackEndsRoundAndMarksInsuranceWin() async {
        let game = makeTestGame()
        game.prepareInsuranceOfferForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .nine),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ace),
                Card(suit: .diamonds, rank: .king),
            ]
        )
        await game.resolveInsuranceDecision(didBuyInsurance: true)
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerLose)
        #expect(game.lastInsuranceWon)
        #expect(game.dealerHoleRevealed)
        #expect(game.outcomeMessage == L10n.t("outcome.dealerBJInsurancePaid"))
    }

    @Test func dealerAcePeekBlackjackWithoutInsurance() async {
        let game = makeTestGame()
        game.prepareInsuranceOfferForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .eight),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ace),
                Card(suit: .diamonds, rank: .queen),
            ]
        )
        await game.resolveInsuranceDecision(didBuyInsurance: false)
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerLose)
        #expect(game.lastInsuranceWon == false)
        #expect(game.outcomeMessage == L10n.t("outcome.dealerBJLose"))
    }

    @Test func nonAceUpcardSkipsInsuranceOffer() async {
        let game = makeTestGame()
        game.installOrderedShoeForTesting([
            Card(suit: .spades, rank: .ten),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .diamonds, rank: .eight),
            Card(suit: .clubs, rank: .seven),
        ])
        await game.startNewRound()
        #expect(game.phase == .playerTurn)
        #expect(game.dealerUpcardIsAce == false)
    }

    @Test func surrenderEndsRoundWithSurrenderOutcome() {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .six),
            ],
            dealer: [
                Card(suit: .clubs, rank: .nine),
                Card(suit: .diamonds, rank: .five),
            ]
        )
        #expect(game.canSurrenderHand)
        game.surrender()
        #expect(game.phase == .finished)
        #expect(game.lastOutcome == .playerSurrender)
        #expect(game.outcomeMessage == L10n.t("outcome.surrender"))
        #expect(game.dealerHoleRevealed)
        #expect(game.playerCards.count == 2)
    }

    @Test func surrenderUnavailableAfterHit() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .five),
                Card(suit: .hearts, rank: .six),
            ],
            dealer: [
                Card(suit: .clubs, rank: .ten),
                Card(suit: .diamonds, rank: .seven),
            ]
        )
        game.replaceRemainingShoeForTesting([
            Card(suit: .diamonds, rank: .two),
        ])
        await game.hit()
        #expect(game.phase == .playerTurn)
        #expect(game.canSurrenderHand == false)
        #expect(game.surrenderHandDisabledReason == L10n.t("disabled.surrenderOnlyTwoCards"))
    }

    @Test func cancelPendingWorkClearsPeekAndHints() async {
        let game = makeTestGame()
        game.preparePlayerTurnForTesting(
            player: [
                Card(suit: .spades, rank: .ten),
                Card(suit: .hearts, rank: .seven),
            ],
            dealer: [
                Card(suit: .clubs, rank: .nine),
                Card(suit: .diamonds, rank: .four),
            ]
        )
        // Instant 时钟下 peek 会瞬间结束；先手动置状态再取消。
        game.cancelPendingWork()
        #expect(game.isPeekingHoleCard == false)
        #expect(game.propActionHint == nil)
        #expect(game.reshufflePulseIndex == nil)
    }

    @Test func sessionConfigurationAppliesTableLimitsAndUnlock() {
        let config = SessionConfiguration.challenge(
            preset: .light,
            unlockRounds: 3
        )
        config.applyToProcessGlobals()
        #expect(ActiveTableLimits.minimumBet == 50)
        #expect(ActiveTableLimits.betChipValues == [50, 100, 250])
        #expect(ActivePreDealAllInUnlock.requiredRounds == 3)

        SessionConfiguration.challenge(
            preset: .standard,
            unlockRounds: ChipRules.defaultPreDealAllInUnlockCompletedRounds
        ).applyToProcessGlobals()
    }

    private func makeTestGame() -> BlackjackGame {
        BlackjackGame(
            practiceMode: .singleDeck,
            cutCardMode: .off,
            timing: InstantGameTiming(),
            feedback: SilentGameFeedback()
        )
    }
}
