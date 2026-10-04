//
//  SplitRules.swift
//  cards
//
//  L2：分牌资格。仅同点数的起手两张；10/J/Q/K 点数相同可分。
//

import Foundation

enum SplitRules {
    /// 两张牌点数相同（A 与 A，或 10 点牌彼此）。
    static func samePointValue(_ a: Rank, _ b: Rank) -> Bool {
        a.blackjackValue == b.blackjackValue
    }

    static func isAcePair(_ a: Rank, _ b: Rank) -> Bool {
        a == .ace && b == .ace
    }
}
