//
//  Deck.swift
//  cards
//

import Foundation

struct Deck: Sendable {
    private(set) var cards: [Card]

    init() {
        var built: [Card] = []
        built.reserveCapacity(52)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                built.append(Card(suit: suit, rank: rank))
            }
        }
        self.cards = built
    }

    mutating func shuffle() {
        cards.shuffle()
    }

    mutating func draw() -> Card? {
        if cards.isEmpty { return nil }
        return cards.removeFirst()
    }
}
