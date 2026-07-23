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

    /// 是否为软牌（至少一张 A 按 11 计入 `bestValue`）。
    var isSoft: Bool {
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
        return aceCount > 0 && total + 10 <= 21
    }

    /// 软 17（best == 17 且含按 11 计的 A）；庄家 H17 规则用。
    var isSoftSeventeen: Bool {
        bestValue == 17 && isSoft
    }
}
