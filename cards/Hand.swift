//
//  Hand.swift
//  cards
//

import Foundation

struct Hand: Sendable {
    let cards: [Card]

    /// 最优点数（A 按 1/11 取不超过 21 的最大值）
    var bestValue: Int {
        var total = 0
        var aceCount = 0
        for card in cards {
            if card.rank == .ace {
                aceCount += 1
                total += 1
            } else {
                total += card.rank.blackjackValue
            }
        }
        if aceCount > 0, total + 10 <= 21 {
            total += 10
        }
        return total
    }

    var isBusted: Bool { bestValue > 21 }

    /// 两张牌且点数为 21（黑杰克）
    var isNaturalBlackjack: Bool {
        cards.count == 2 && bestValue == 21
    }
}
