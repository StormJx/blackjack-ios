//
//  BasicStrategy.swift
//  cards
//
//  T1：多副、庄家软 17 停（S17）、可晚投降的基础策略。纯查表，零 UI。
//  表源：Wizard of Odds 4–8 副 S17 文本策略（投降 / 分牌 / 加倍 / 要停）。
//

import Foundation

enum StrategyAction: String, Equatable, Sendable, CaseIterable {
    case hit
    case stand
    case double
    case surrender
    case split
}

/// 查表用手牌分类。对子按点数归并（T/J/Q/K 均为 10）。
enum StrategyHand: Equatable, Sendable {
    case hard(Int)
    case soft(Int)
    case pair(Rank)
}

enum BasicStrategy {

    /// 静态查表。不可加倍 / 投降 / 分牌时走单元格回退（加倍→要或停，投降→要，分牌→硬/软点）。
    static func advise(
        hand: StrategyHand,
        dealerUp: Rank,
        canDouble: Bool = true,
        canSurrender: Bool = true,
        canSplit: Bool = true
    ) -> StrategyAction {
        let col = dealerColumn(dealerUp)
        switch hand {
        case .pair(let rank):
            if canSplit {
                let cell = pairTable[pairRow(rank)][col]
                if cell == .split { return .split }
                return resolve(cell, canDouble: canDouble, canSurrender: canSurrender)
            }
            return advise(
                hand: pairFallback(rank),
                dealerUp: dealerUp,
                canDouble: canDouble,
                canSurrender: canSurrender,
                canSplit: false
            )
        case .hard(let total):
            return resolve(hardTable[hardRow(total)][col], canDouble: canDouble, canSurrender: canSurrender)
        case .soft(let total):
            return resolve(softTable[softRow(total)][col], canDouble: canDouble, canSurrender: canSurrender)
        }
    }

    static func classify(_ cards: [Card]) -> StrategyHand {
        if cards.count == 2 {
            let a = normalizedPairRank(cards[0].rank)
            let b = normalizedPairRank(cards[1].rank)
            if a == b { return .pair(a) }
        }
        let hand = Hand(cards: cards)
        if hand.isSoft { return .soft(hand.bestValue) }
        return .hard(hand.bestValue)
    }

    static func advise(
        playerCards: [Card],
        dealerUp: Rank,
        canDouble: Bool,
        canSurrender: Bool,
        canSplit: Bool
    ) -> StrategyAction {
        advise(
            hand: classify(playerCards),
            dealerUp: dealerUp,
            canDouble: canDouble,
            canSurrender: canSurrender,
            canSplit: canSplit
        )
    }
}

// MARK: - 单元格与回退

private enum StrategyCell: Equatable {
    case hit
    case stand
    case doubleOrHit
    case doubleOrStand
    case surrenderOrHit
    case split
}

private func resolve(_ cell: StrategyCell, canDouble: Bool, canSurrender: Bool) -> StrategyAction {
    switch cell {
    case .hit: return .hit
    case .stand: return .stand
    case .doubleOrHit: return canDouble ? .double : .hit
    case .doubleOrStand: return canDouble ? .double : .stand
    case .surrenderOrHit: return canSurrender ? .surrender : .hit
    case .split: return .split
    }
}

private func pairFallback(_ rank: Rank) -> StrategyHand {
    if normalizedPairRank(rank) == .ace { return .soft(12) }
    return .hard(normalizedPairRank(rank).blackjackValue * 2)
}

private func normalizedPairRank(_ rank: Rank) -> Rank {
    switch rank {
    case .ten, .jack, .queen, .king: return .ten
    default: return rank
    }
}

private func dealerColumn(_ rank: Rank) -> Int {
    switch rank {
    case .two: return 0
    case .three: return 1
    case .four: return 2
    case .five: return 3
    case .six: return 4
    case .seven: return 5
    case .eight: return 6
    case .nine: return 7
    case .ten, .jack, .queen, .king: return 8
    case .ace: return 9
    }
}

private func hardRow(_ total: Int) -> Int {
    min(max(total, 5), 21) - 5
}

private func softRow(_ total: Int) -> Int {
    min(max(total, 12), 21) - 12
}

private func pairRow(_ rank: Rank) -> Int {
    switch normalizedPairRank(rank) {
    case .two: return 0
    case .three: return 1
    case .four: return 2
    case .five: return 3
    case .six: return 4
    case .seven: return 5
    case .eight: return 6
    case .nine: return 7
    case .ten: return 8
    case .ace: return 9
    default: return 0
    }
}

// MARK: - 静态表（列：庄家 2 3 4 5 6 7 8 9 10 A）

private let H = StrategyCell.hit
private let S = StrategyCell.stand
private let D = StrategyCell.doubleOrHit
private let Ds = StrategyCell.doubleOrStand
private let Rh = StrategyCell.surrenderOrHit
private let P = StrategyCell.split

/// 硬点 5…21。4 与更低并入 5（全要）。
private let hardTable: [[StrategyCell]] = [
    /*  5 */ [H, H, H, H, H, H, H, H, H, H],
    /*  6 */ [H, H, H, H, H, H, H, H, H, H],
    /*  7 */ [H, H, H, H, H, H, H, H, H, H],
    /*  8 */ [H, H, H, H, H, H, H, H, H, H],
    /*  9 */ [H, D, D, D, D, H, H, H, H, H],
    /* 10 */ [D, D, D, D, D, D, D, D, H, H],
    /* 11 */ [D, D, D, D, D, D, D, D, D, H],
    /* 12 */ [H, H, S, S, S, H, H, H, H, H],
    /* 13 */ [S, S, S, S, S, H, H, H, H, H],
    /* 14 */ [S, S, S, S, S, H, H, H, H, H],
    /* 15 */ [S, S, S, S, S, H, H, H, Rh, H],
    /* 16 */ [S, S, S, S, S, H, H, Rh, Rh, Rh],
    /* 17 */ [S, S, S, S, S, S, S, S, S, S],
    /* 18 */ [S, S, S, S, S, S, S, S, S, S],
    /* 19 */ [S, S, S, S, S, S, S, S, S, S],
    /* 20 */ [S, S, S, S, S, S, S, S, S, S],
    /* 21 */ [S, S, S, S, S, S, S, S, S, S],
]

/// 软点 12…21。12 仅作「对 A 不可分」回退（全要）。
private let softTable: [[StrategyCell]] = [
    /* 12 */ [H, H, H, H, H, H, H, H, H, H],
    /* 13 */ [H, H, H, D, D, H, H, H, H, H],
    /* 14 */ [H, H, H, D, D, H, H, H, H, H],
    /* 15 */ [H, H, D, D, D, H, H, H, H, H],
    /* 16 */ [H, H, D, D, D, H, H, H, H, H],
    /* 17 */ [H, D, D, D, D, H, H, H, H, H],
    /* 18 */ [S, Ds, Ds, Ds, Ds, S, S, H, H, H],
    /* 19 */ [S, S, S, S, S, S, S, S, S, S],
    /* 20 */ [S, S, S, S, S, S, S, S, S, S],
    /* 21 */ [S, S, S, S, S, S, S, S, S, S],
]

/// 对子：2,3,4,5,6,7,8,9,10,A。S17 下 8,8 对 A 仍分（H17 才投降）。
private let pairTable: [[StrategyCell]] = [
    /* 2,2 */ [P, P, P, P, P, P, H, H, H, H],
    /* 3,3 */ [P, P, P, P, P, P, H, H, H, H],
    /* 4,4 */ [H, H, H, P, P, H, H, H, H, H],
    /* 5,5 */ [D, D, D, D, D, D, D, D, H, H],
    /* 6,6 */ [P, P, P, P, P, H, H, H, H, H],
    /* 7,7 */ [P, P, P, P, P, P, H, H, H, H],
    /* 8,8 */ [P, P, P, P, P, P, P, P, P, P],
    /* 9,9 */ [P, P, P, P, P, S, P, P, S, S],
    /* TT  */ [S, S, S, S, S, S, S, S, S, S],
    /* A,A */ [P, P, P, P, P, P, P, P, P, P],
]
