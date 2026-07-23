//
//  Deck.swift
//  cards
//
//  阶段 2（v1.6）：持久牌堆 + 切牌渗透率；规则见 VERSION_ROADMAP「切牌与重洗」。
//

import Foundation

struct Deck: Sendable {
    let numberOfDecks: Int
    /// E2：关切牌时，只要已发过牌，下一局开始前必整副重洗（无渗透）。
    var cutCardEnabled: Bool
    private(set) var cards: [Card]
    private(set) var totalCardCount: Int
    /// 本副累计已发张数（含当前局）。
    private(set) var dealtCount: Int = 0
    /// 达到该已发张数后，下一局开始前通常须整副重洗（本局可发完；尾牌例外见下）。
    private(set) var cutPosition: Int = 0

    /// 开局发四张所需最少剩余牌数；不足则无法开局，须先重洗。
    static let minimumCardsForRound = 4
    /// 已过切牌点时：若剩余仍 ≥ 此值，局间重洗；若剩余更少，则再开一局打完尾牌后再重洗。
    static let playOutThresholdWhenPastCut = 7
    /// 切牌点落在总牌数的该比例区间（50%–75% 渗透率）。
    static let cutPenetrationRange: ClosedRange<Double> = 0.50...0.75

    /// - Parameter numberOfDecks: 完整 52 张牌的副数；`1` 为一副，多副时为 N 副合并成一整副牌堆。
    /// - Parameter cutCardEnabled: 是否启用切牌渗透；`false` 时每局打完后下一局必重洗。
    init(numberOfDecks: Int = 1, cutCardEnabled: Bool = true) {
        precondition(numberOfDecks >= 1, "numberOfDecks must be >= 1")
        self.numberOfDecks = numberOfDecks
        self.cutCardEnabled = cutCardEnabled
        let built = Self.buildCards(numberOfDecks: numberOfDecks)
        self.cards = built
        self.totalCardCount = built.count
        self.cutPosition = totalCardCount
    }

    var remainingCount: Int { cards.count }

    /// 下一局开始前是否应整副重洗。
    /// - 切牌关闭：已发过任意牌（或不足开局四张）→ 重洗。
    /// - 剩余不足以发开局四张 → 必须重洗。
    /// - 已达切牌点且剩余 ≥ 7 → 局间重洗。
    /// - 已达切牌点但剩余 4…6 张 → 不重洗，再开一局打完尾牌后分胜负。
    var needsReshuffleBeforeNextRound: Bool {
        if remainingCount < Self.minimumCardsForRound {
            return true
        }
        if !cutCardEnabled {
            return remainingCount < totalCardCount
        }
        if dealtCount >= cutPosition {
            return remainingCount >= Self.playOutThresholdWhenPastCut
        }
        return false
    }

    mutating func shuffle() {
        var rng = SystemRandomNumberGenerator()
        shuffleAndCut(using: &rng)
    }

    mutating func shuffle<R: RandomNumberGenerator>(using rng: inout R) {
        shuffleAndCut(using: &rng)
    }

    /// 整副重洗并重新插入切牌点。
    mutating func shuffleAndCut() {
        var rng = SystemRandomNumberGenerator()
        shuffleAndCut(using: &rng)
    }

    mutating func shuffleAndCut<R: RandomNumberGenerator>(using rng: inout R) {
        cards = Self.buildCards(numberOfDecks: numberOfDecks)
        totalCardCount = cards.count
        cards.shuffle(using: &rng)
        dealtCount = 0
        let minCut = max(1, Int(Double(totalCardCount) * Self.cutPenetrationRange.lowerBound))
        let maxCut = max(minCut, Int(Double(totalCardCount) * Self.cutPenetrationRange.upperBound))
        cutPosition = Int.random(in: minCut...maxCut, using: &rng)
    }

    mutating func draw() -> Card? {
        guard !cards.isEmpty else { return nil }
        dealtCount += 1
        return cards.removeFirst()
    }

    /// 规划道具 `reshuffleDealerCard`：将一张牌插回剩余牌堆随机位置（不重算切牌点 / dealtCount）。
    /// - Note: 效果尚未由 UI 接线；单测与实现时再锁边界（暗牌可否、每局限次等）。
    mutating func returnCardToShoe(_ card: Card) {
        var rng = SystemRandomNumberGenerator()
        returnCardToShoe(card, using: &rng)
    }

    mutating func returnCardToShoe<R: RandomNumberGenerator>(_ card: Card, using rng: inout R) {
        if cards.isEmpty {
            cards = [card]
            return
        }
        let index = Int.random(in: 0...cards.count, using: &rng)
        cards.insert(card, at: index)
    }

    private static func buildCards(numberOfDecks: Int) -> [Card] {
        var built: [Card] = []
        built.reserveCapacity(52 * numberOfDecks)
        for _ in 0..<numberOfDecks {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    built.append(Card(suit: suit, rank: rank))
                }
            }
        }
        return built
    }
}
