//
//  BlackjackGame.swift
//  cards
//

import Foundation
import SwiftUI

@MainActor
final class BlackjackGame: ObservableObject {
    enum Phase: Equatable {
        case idle
        case dealing
        case playerTurn
        case dealerTurn
        case finished
    }

    @Published private(set) var playerCards: [Card] = []
    @Published private(set) var dealerCards: [Card] = []
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var outcomeMessage: String = ""
    /// 任意发牌 / 翻牌 / 补牌 / 新局收牌动画进行中，禁用操作
    @Published private(set) var isAnimating: Bool = false
    /// 庄家回合：暗牌尚未翻开时为 false，翻开后为 true
    @Published private(set) var dealerHoleRevealed: Bool = true
    /// 新局：收牌区（手牌 + 上局结果）整体透明度，用于收牌淡出
    @Published private(set) var handAreaOpacity: Double = 1
    /// 新局：收牌区轻微缩小，配合淡出
    @Published private(set) var handAreaScale: CGFloat = 1
    /// 每局递增，用于牌视图 identity，避免动画串台
    @Published private(set) var roundToken: Int = 0
    /// 新局洗牌提示（短文案）
    @Published private(set) var dealingCaption: String?

    private var deck = Deck()

    private let delayInitialDeal: UInt64 = 165_000_000
    private let delayAfterDealStep: UInt64 = 95_000_000
    private let delayBeforeHoleFlip: UInt64 = 320_000_000
    private let delayAfterHoleFlip: UInt64 = 380_000_000
    private let delayDealerHit: UInt64 = 260_000_000
    private let delayAfterHit: UInt64 = 200_000_000
    private let delayClearFadeOut: UInt64 = 400_000_000
    private let delayClearFadeIn: UInt64 = 200_000_000
    private let delayShuffleCaption: UInt64 = 340_000_000

    var playerBestValue: Int {
        Hand(cards: playerCards).bestValue
    }

    var dealerBestValue: Int {
        Hand(cards: dealerCards).bestValue
    }

    /// 玩家回合或发牌中或庄家未翻暗牌时，第二张庄家牌盖着
    var hideDealerHoleCard: Bool {
        guard dealerCards.count >= 2 else { return false }
        if phase == .playerTurn || phase == .dealing { return true }
        if phase == .dealerTurn && !dealerHoleRevealed { return true }
        return false
    }

    func startNewRound() async {
        guard !isAnimating else { return }
        isAnimating = true
        dealerHoleRevealed = true
        dealingCaption = nil

        roundToken += 1

        let hadCards = !playerCards.isEmpty || !dealerCards.isEmpty
        if hadCards {
            withAnimation(.easeInOut(duration: 0.36)) {
                handAreaOpacity = 0
                handAreaScale = 0.9
            }
            try? await Task.sleep(nanoseconds: delayClearFadeOut)
        }

        outcomeMessage = ""
        playerCards = []
        dealerCards = []

        deck = Deck()
        deck.shuffle()

        if hadCards {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                handAreaOpacity = 1
                handAreaScale = 1
            }
            try? await Task.sleep(nanoseconds: delayClearFadeIn)
        }

        dealingCaption = "洗牌中…"
        GameFeedback.shared.shuffleHint()
        try? await Task.sleep(nanoseconds: delayShuffleCaption)
        dealingCaption = nil

        phase = .dealing

        guard let c1 = deck.draw(), let c2 = deck.draw(), let c3 = deck.draw(), let c4 = deck.draw() else {
            outcomeMessage = "洗牌异常，请重试"
            phase = .finished
            GameFeedback.shared.notifyError()
            isAnimating = false
            return
        }

        try? await Task.sleep(nanoseconds: delayInitialDeal)

        withAnimation(cardDealAnimation) {
            playerCards = [c1]
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterDealStep)

        withAnimation(cardDealAnimation) {
            dealerCards = [c2]
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterDealStep)

        withAnimation(cardDealAnimation) {
            playerCards = [c1, c3]
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterDealStep)

        withAnimation(cardDealAnimation) {
            dealerCards = [c2, c4]
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterDealStep)

        let playerHand = Hand(cards: playerCards)
        if playerHand.isNaturalBlackjack {
            resolvePlayerNaturalBlackjack()
            isAnimating = false
            return
        }

        phase = .playerTurn
        isAnimating = false
    }

    func hit() async {
        guard phase == .playerTurn, !isAnimating else { return }
        isAnimating = true
        defer {
            if phase == .playerTurn { isAnimating = false }
        }

        try? await Task.sleep(nanoseconds: delayAfterHit)

        guard let card = deck.draw() else {
            outcomeMessage = "牌堆已空"
            phase = .finished
            GameFeedback.shared.notifyError()
            isAnimating = false
            return
        }

        withAnimation(cardDealAnimation) {
            playerCards.append(card)
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterHit)

        let hand = Hand(cards: playerCards)
        if hand.isBusted {
            outcomeMessage = "爆牌，你输了"
            phase = .finished
            GameFeedback.shared.roundOutcome(playerWon: false, isPush: false)
            isAnimating = false
            return
        }
        if hand.bestValue == 21 {
            await playDealerTurnAsync()
            return
        }
    }

    func stand() async {
        guard phase == .playerTurn, !isAnimating else { return }
        await playDealerTurnAsync()
    }

    private var cardDealAnimation: Animation {
        .spring(response: 0.38, dampingFraction: 0.78)
    }

    private func resolvePlayerNaturalBlackjack() {
        let dealerHand = Hand(cards: dealerCards)
        if dealerHand.isNaturalBlackjack {
            outcomeMessage = "双方黑杰克，平局"
            GameFeedback.shared.roundOutcome(playerWon: nil, isPush: true)
        } else {
            outcomeMessage = "黑杰克！你赢了"
            GameFeedback.shared.roundOutcome(playerWon: true, isPush: false)
        }
        phase = .finished
    }

    private func playDealerTurnAsync() async {
        isAnimating = true
        phase = .dealerTurn
        dealerHoleRevealed = false

        try? await Task.sleep(nanoseconds: delayBeforeHoleFlip)

        withAnimation(.easeInOut(duration: 0.35)) {
            dealerHoleRevealed = true
        }
        GameFeedback.shared.holeRevealed()
        try? await Task.sleep(nanoseconds: delayAfterHoleFlip)

        var hand = Hand(cards: dealerCards)
        while hand.bestValue < 17 {
            guard let card = deck.draw() else { break }
            withAnimation(cardDealAnimation) {
                dealerCards.append(card)
            }
            GameFeedback.shared.cardDealt()
            try? await Task.sleep(nanoseconds: delayDealerHit)
            hand = Hand(cards: dealerCards)
        }

        resolveOutcome()
        phase = .finished
        isAnimating = false
    }

    private func resolveOutcome() {
        let p = Hand(cards: playerCards).bestValue
        let d = Hand(cards: dealerCards).bestValue

        if d > 21 {
            outcomeMessage = "庄家爆牌，你赢了"
            GameFeedback.shared.roundOutcome(playerWon: true, isPush: false)
        } else if p > d {
            outcomeMessage = "你赢了"
            GameFeedback.shared.roundOutcome(playerWon: true, isPush: false)
        } else if p < d {
            outcomeMessage = "你输了"
            GameFeedback.shared.roundOutcome(playerWon: false, isPush: false)
        } else {
            outcomeMessage = "平局"
            GameFeedback.shared.roundOutcome(playerWon: nil, isPush: true)
        }
    }
}
