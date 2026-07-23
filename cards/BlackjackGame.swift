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
    /// 新局洗牌提示（短文案；局间全屏洗牌时同步为「洗牌中…」）
    @Published private(set) var dealingCaption: String?
    /// 局间需要重洗时展示专用洗牌页（盖住牌桌）
    @Published private(set) var isShowingShuffleScreen: Bool = false
    /// 当前牌堆剩余张数（局间 / 局中均可读）
    @Published private(set) var remainingCardCount: Int = 0
    /// 当前模式整副总张数
    @Published private(set) var totalCardCount: Int = 0
    /// 本局胜负类别（供筹码结算模块消费；不含金额）
    @Published private(set) var lastOutcome: RoundOutcome?
    /// 娱乐道具：本局已开启「庄家软 17 要牌」。
    @Published private(set) var dealerHitsSoft17ThisRound = false
    /// 娱乐道具：正在窥视暗牌（约 1 秒）。
    @Published private(set) var isPeekingHoleCard = false
    /// 娱乐道具：本局已用过窥视。
    @Published private(set) var hasPeekedHoleThisRound = false
    /// 娱乐道具：本局已用过换一张。
    @Published private(set) var hasRedrawnThisRound = false

    /// 当前练习变体（一副 / 两副 / 六副）；整局生命周期内不变。
    let practiceMode: PracticeMode
    /// E2：本会话是否启用切牌（来自设置；会话内不变）。
    let cutCardEnabled: Bool

    /// 成就：本局曾在 >17 / >18 / >19 点要牌且该次未爆；以及 20→21。
    private var hitSurvivedFromOver17 = false
    private var hitSurvivedFromOver18 = false
    private var hitSurvivedFromOver19 = false
    private var hitFrom20To21 = false

    private var deck: Deck
    private var peekTask: Task<Void, Never>?

    init(practiceMode: PracticeMode = .singleDeck, cutCardEnabled: Bool = true) {
        self.practiceMode = practiceMode
        self.cutCardEnabled = cutCardEnabled
        var initialDeck = Deck(
            numberOfDecks: practiceMode.numberOfDecks,
            cutCardEnabled: cutCardEnabled
        )
        initialDeck.shuffleAndCut()
        self.deck = initialDeck
        self.remainingCardCount = initialDeck.remainingCount
        self.totalCardCount = initialDeck.totalCardCount
    }

    /// 成就判定用快照（仅在 `phase == .finished` 且有 `lastOutcome` 时有意义）。
    func makeRoundSnapshot(wasAllInBet: Bool = false) -> RoundSnapshot? {
        guard let outcome = lastOutcome else { return nil }
        let playerHand = Hand(cards: playerCards)
        let dealerHand = Hand(cards: dealerCards)
        return RoundSnapshot(
            outcome: outcome,
            playerCardCount: playerCards.count,
            playerBest: playerHand.bestValue,
            dealerBest: dealerHand.bestValue,
            playerBusted: playerHand.isBusted,
            dealerBusted: dealerHand.isBusted,
            playerNaturalBlackjack: playerHand.isNaturalBlackjack,
            hitSurvivedFromOver17: hitSurvivedFromOver17,
            hitSurvivedFromOver18: hitSurvivedFromOver18,
            hitSurvivedFromOver19: hitSurvivedFromOver19,
            hitFrom20To21: hitFrom20To21,
            wasAllInBet: wasAllInBet
        )
    }

    private let delayInitialDeal: UInt64 = 165_000_000
    private let delayAfterDealStep: UInt64 = 95_000_000
    private let delayBeforeHoleFlip: UInt64 = 320_000_000
    private let delayAfterHoleFlip: UInt64 = 380_000_000
    private let delayDealerHit: UInt64 = 260_000_000
    private let delayAfterHit: UInt64 = 200_000_000
    private let delayClearFadeOut: UInt64 = 400_000_000
    private let delayClearFadeIn: UInt64 = 200_000_000
    /// 局间全屏洗牌页停留时长
    private let delayShuffleScreen: UInt64 = 1_600_000_000
    private let delayPeekHole: UInt64 = 1_000_000_000

    var playerBestValue: Int {
        Hand(cards: playerCards).bestValue
    }

    var dealerBestValue: Int {
        Hand(cards: dealerCards).bestValue
    }

    /// 是否可换最近一次要牌得到的牌（须已要过至少一张）。
    var canRedrawLastHitCard: Bool {
        phase == .playerTurn && !isAnimating && playerCards.count > 2 && !hasRedrawnThisRound
    }

    /// 是否可开启本局庄家软 17 要牌。
    var canActivateDealerSoft17Hit: Bool {
        phase == .playerTurn && !isAnimating && !dealerHitsSoft17ThisRound
    }

    /// 是否可窥视暗牌。
    var canPeekHoleCard: Bool {
        phase == .playerTurn
            && !isAnimating
            && !hasPeekedHoleThisRound
            && !isPeekingHoleCard
            && dealerCards.count >= 2
    }

    /// 牌桌副标题：共 N 张 + 剩余张数。
    var shoeStatusLine: String {
        "共 \(totalCardCount) 张，剩余 \(remainingCardCount) 张"
    }

    /// 下一局发牌前是否会整副重洗（下注页据此判断「剩余张数」是否仍是本局牌况）。
    var willReshuffleBeforeNextRound: Bool {
        deck.needsReshuffleBeforeNextRound
    }

    /// 一副牌且本局将以剩余 ≤15 张开打时，开局「全下」用强调样式（强制全下）。
    var isForcedAllInAvailable: Bool {
        ChipRules.canUseForcedAllIn(
            isSingleDeck: practiceMode == .singleDeck,
            remainingCards: remainingCardCount,
            willReshuffle: willReshuffleBeforeNextRound
        )
    }

    /// 玩家回合或发牌中或庄家未翻暗牌时，第二张庄家牌盖着（窥视中除外）。
    var hideDealerHoleCard: Bool {
        if isPeekingHoleCard { return false }
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
        isShowingShuffleScreen = false

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
        lastOutcome = nil
        playerCards = []
        dealerCards = []
        hitSurvivedFromOver17 = false
        hitSurvivedFromOver18 = false
        hitSurvivedFromOver19 = false
        hitFrom20To21 = false
        resetRoundPropState()

        if hadCards {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                handAreaOpacity = 1
                handAreaScale = 1
            }
            try? await Task.sleep(nanoseconds: delayClearFadeIn)
        }

        if deck.needsReshuffleBeforeNextRound {
            await presentShuffleScreenAndReshuffle()
        }

        phase = .dealing
        publishDeckCounts()

        guard let c1 = deck.draw(), let c2 = deck.draw(), let c3 = deck.draw(), let c4 = deck.draw() else {
            outcomeMessage = "洗牌异常，请重试"
            phase = .finished
            GameFeedback.shared.notifyError()
            isAnimating = false
            publishDeckCounts()
            return
        }
        publishDeckCounts()

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
        // 天然黑杰克见牌即结算，不进入玩家回合。默认全下在发牌前，故仍可吃到开局全下。
        // 见牌后再全下由道具 `PropStore.owns(.midHandAllIn)` 门控。
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

        let beforeBest = Hand(cards: playerCards).bestValue

        guard let card = deck.draw() else {
            // 尾牌已尽：不再报错，按现有手牌进入庄家回合并结算。
            publishDeckCounts()
            await playDealerTurnAsync()
            return
        }
        publishDeckCounts()

        withAnimation(cardDealAnimation) {
            playerCards.append(card)
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterHit)

        let hand = Hand(cards: playerCards)
        if hand.isBusted {
            finishRound(
                message: "爆牌，你输了",
                outcome: .playerLose,
                playerWon: false,
                isPush: false
            )
            isAnimating = false
            return
        }

        // 成就：高点要牌未爆（本局内累计；最终是否解锁看是否获胜）。
        if beforeBest > 17 { hitSurvivedFromOver17 = true }
        if beforeBest > 18 { hitSurvivedFromOver18 = true }
        if beforeBest > 19 { hitSurvivedFromOver19 = true }
        if beforeBest == 20 && hand.bestValue == 21 {
            hitFrom20To21 = true
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

    /// 娱乐道具：本局开启庄家软 17 要牌。
    @discardableResult
    func activateDealerSoft17Hit() -> Bool {
        guard canActivateDealerSoft17Hit else { return false }
        dealerHitsSoft17ThisRound = true
        return true
    }

    /// 娱乐道具：窥视暗牌约 1 秒（每局限 1 次）。
    func peekHoleCard() async {
        guard canPeekHoleCard else { return }
        hasPeekedHoleThisRound = true
        isPeekingHoleCard = true
        GameFeedback.shared.holeRevealed()
        peekTask?.cancel()
        peekTask = Task {
            try? await Task.sleep(nanoseconds: delayPeekHole)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isPeekingHoleCard = false
            }
        }
        await peekTask?.value
    }

    /// 娱乐道具：换掉最近一次要牌得到的牌（每局限 1 次）。
    func redrawLastHitCard() async {
        guard canRedrawLastHitCard else { return }
        isAnimating = true
        defer {
            if phase == .playerTurn { isAnimating = false }
        }

        hasRedrawnThisRound = true
        let beforeBest = Hand(cards: Array(playerCards.dropLast())).bestValue
        playerCards.removeLast()

        guard let card = deck.draw() else {
            publishDeckCounts()
            await playDealerTurnAsync()
            return
        }
        publishDeckCounts()

        withAnimation(cardDealAnimation) {
            playerCards.append(card)
        }
        GameFeedback.shared.cardDealt()
        try? await Task.sleep(nanoseconds: delayAfterHit)

        let hand = Hand(cards: playerCards)
        if hand.isBusted {
            finishRound(
                message: "爆牌，你输了",
                outcome: .playerLose,
                playerWon: false,
                isPush: false
            )
            isAnimating = false
            return
        }

        if beforeBest > 17 { hitSurvivedFromOver17 = true }
        if beforeBest > 18 { hitSurvivedFromOver18 = true }
        if beforeBest > 19 { hitSurvivedFromOver19 = true }
        if beforeBest == 20 && hand.bestValue == 21 {
            hitFrom20To21 = true
        }

        if hand.bestValue == 21 {
            await playDealerTurnAsync()
        }
    }

    private func resetRoundPropState() {
        peekTask?.cancel()
        peekTask = nil
        dealerHitsSoft17ThisRound = false
        isPeekingHoleCard = false
        hasPeekedHoleThisRound = false
        hasRedrawnThisRound = false
    }

    private var cardDealAnimation: Animation {
        .spring(response: 0.38, dampingFraction: 0.78)
    }

    private func dealerShouldHit(_ hand: Hand) -> Bool {
        if hand.bestValue < 17 { return true }
        if dealerHitsSoft17ThisRound && hand.isSoftSeventeen { return true }
        return false
    }

    private func resolvePlayerNaturalBlackjack() {
        let dealerHand = Hand(cards: dealerCards)
        if dealerHand.isNaturalBlackjack {
            finishRound(
                message: "双方黑杰克，平局",
                outcome: .push,
                playerWon: nil,
                isPush: true
            )
        } else {
            finishRound(
                message: "黑杰克！你赢了（\(ChipRules.blackjackOddsLabel)）",
                outcome: .playerBlackjack,
                playerWon: true,
                isPush: false
            )
        }
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
        while dealerShouldHit(hand) {
            guard let card = deck.draw() else { break }
            publishDeckCounts()
            withAnimation(cardDealAnimation) {
                dealerCards.append(card)
            }
            GameFeedback.shared.cardDealt()
            try? await Task.sleep(nanoseconds: delayDealerHit)
            hand = Hand(cards: dealerCards)
        }

        resolveOutcome()
        isAnimating = false
    }

    /// 局间全屏洗牌：展示洗牌页 → 播提示音 → 整副重洗并更新剩余张数。
    private func presentShuffleScreenAndReshuffle() async {
        withAnimation(.easeInOut(duration: 0.28)) {
            isShowingShuffleScreen = true
            dealingCaption = "洗牌中…"
        }
        GameFeedback.shared.shuffleHint()
        try? await Task.sleep(nanoseconds: delayShuffleScreen)
        deck.shuffleAndCut()
        publishDeckCounts()
        withAnimation(.easeInOut(duration: 0.28)) {
            isShowingShuffleScreen = false
            dealingCaption = nil
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
    }

    private func publishDeckCounts() {
        remainingCardCount = deck.remainingCount
        totalCardCount = deck.totalCardCount
    }

    private func resolveOutcome() {
        let p = Hand(cards: playerCards).bestValue
        let d = Hand(cards: dealerCards).bestValue
        let outcome = RoundOutcome.fromFinalPoints(playerBest: p, dealerBest: d)

        switch outcome {
        case .playerWin where d > 21:
            finishRound(
                message: "庄家爆牌，你赢了",
                outcome: .playerWin,
                playerWon: true,
                isPush: false
            )
        case .playerWin:
            finishRound(
                message: "你赢了",
                outcome: .playerWin,
                playerWon: true,
                isPush: false
            )
        case .playerLose:
            finishRound(
                message: "你输了",
                outcome: .playerLose,
                playerWon: false,
                isPush: false
            )
        case .push:
            finishRound(
                message: "平局",
                outcome: .push,
                playerWon: nil,
                isPush: true
            )
        case .playerBlackjack:
            // 比点路径不会产生天然黑杰克结局。
            finishRound(
                message: "你赢了",
                outcome: .playerWin,
                playerWon: true,
                isPush: false
            )
        }
    }

    /// 写入结果文案与胜负类别，并触发反馈；筹码结算由 ChipBank 在 UI 层完成。
    private func finishRound(
        message: String,
        outcome: RoundOutcome,
        playerWon: Bool?,
        isPush: Bool
    ) {
        outcomeMessage = message
        lastOutcome = outcome
        phase = .finished
        GameFeedback.shared.roundOutcome(playerWon: playerWon, isPush: isPush)
    }
}

