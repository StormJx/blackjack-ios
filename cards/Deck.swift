//
//  Deck.swift
//  cards
//
//  阶段 2（v1.6）：持久牌堆 + 切牌渗透率；P5 三态见 CutCardMode。
//

import Foundation

struct Deck: Sendable {
    let numberOfDecks: Int
    /// P5：切牌策略（关 / 仪式感 / 真实渗透）。
    var cutCardMode: CutCardMode
    private(set) var cards: [Card]
    private(set) var totalCardCount: Int
    /// 本副累计已发张数（含当前局）。
    private(set) var dealtCount: Int = 0
    /// 达到该已发张数后，下一局开始前通常须整副重洗（本局可发完；尾牌例外见下）。
    /// 仪式感模式仍会插入切牌点供仪式展示，但不参与重洗判定。
    private(set) var cutPosition: Int = 0

    /// 开局发四张所需最少剩余牌数；不足则无法开局，须先重洗。
    static let minimumCardsForRound = 4
    /// 已过切牌点时：若剩余仍 ≥ 此值，局间重洗；若剩余更少，则再开一局打完尾牌后再重洗。
    static let playOutThresholdWhenPastCut = 7
    /// 切牌点落在总牌数的该比例区间（50%–75% 渗透率）。
    static let cutPenetrationRange: ClosedRange<Double> = 0.50...0.75

    /// - Parameter numberOfDecks: 完整 52 张牌的副数；`1` 为一副，多副时为 N 副合并成一整副牌堆。
    /// - Parameter cutCardMode: 切牌策略；见 `CutCardMode`。
    init(numberOfDecks: Int = 1, cutCardMode: CutCardMode = .real) {
        precondition(numberOfDecks >= 1, "numberOfDecks must be >= 1")
        self.numberOfDecks = numberOfDecks
        self.cutCardMode = cutCardMode
        let built = Self.buildCards(numberOfDecks: numberOfDecks)
        self.cards = built
        self.totalCardCount = built.count
        self.cutPosition = totalCardCount
    }

    var remainingCount: Int { cards.count }

    /// 下一局开始前是否应整副重洗。
    /// - 剩余不足以发开局四张 → 必须重洗。
    /// - `.off`：已发过任意牌 → 重洗。
    /// - `.ceremonial`：不按切牌点强制重洗；仅当不足开局四张时重洗（打完副）。
    /// - `.real`：已达切牌点且剩余 ≥ 7 → 局间重洗；剩余 4…6 → 尾牌局不重洗。
    var needsReshuffleBeforeNextRound: Bool {
        if remainingCount < Self.minimumCardsForRound {
            return true
        }
        switch cutCardMode {
        case .off:
            return remainingCount < totalCardCount
        case .ceremonial:
            return false
        case .real:
            if dealtCount >= cutPosition {
                return remainingCount >= Self.playOutThresholdWhenPastCut
            }
            return false
        }
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

    /// 道具 `reshuffleDealerCard`：将一张已发牌插回剩余牌堆随机位置。
    /// - 回退 `dealtCount`（穿透深度按「净发出」计；随后再 `draw` 则净变化为 0）。
    /// - 不重算切牌点。
    /// - 牌堆非空时绝不插到队首，保证紧接着的一次 `draw` 不会原样抽回同一张。
    mutating func returnCardToShoe(_ card: Card) {
        var rng = SystemRandomNumberGenerator()
        returnCardToShoe(card, using: &rng)
    }

    mutating func returnCardToShoe<R: RandomNumberGenerator>(_ card: Card, using rng: inout R) {
        if dealtCount > 0 {
            dealtCount -= 1
        }
        if cards.isEmpty {
            // 鞋内已空：只能原牌回库；紧接着的 draw 仍会抽到它（无其它候选）。
            cards = [card]
            return
        }
        // 1...count：插到现有牌之后或队尾，下一张一定不是刚还回的牌。
        let index = Int.random(in: 1...cards.count, using: &rng)
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
