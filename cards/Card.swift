//
//  Card.swift
//  cards
//

import Foundation

enum Suit: String, CaseIterable, Sendable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
}

enum Rank: CaseIterable, Sendable {
    case ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    /// 用于计算点数时的基础值（A 计为 1，由 Hand 统一处理 11）
    var blackjackValue: Int {
        switch self {
        case .ace: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten, .jack, .queen, .king: return 10
        }
    }

    var shortName: String {
        switch self {
        case .ace: return "A"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        }
    }
}

struct Card: Equatable, Hashable, Sendable {
    let suit: Suit
    let rank: Rank

    var displayLabel: String {
        "\(suit.rawValue)\(rank.shortName)"
    }
}
