//
//  LuckDice.swift
//  cards
//
//  欢迎页小骰子。点数高时，娱乐模式接下来几局给一次后台手气，闯关不受影响。
//

import Foundation

enum LuckDiceRules {
    static let maxDice = 3
    static let buffRounds = 3
    static let storageKey = "luckDice.state"

    /// 1 颗 ≥5，2 颗 ≥9，3 颗 ≥13，算今天运气较好。
    static func isLucky(total: Int, diceCount: Int) -> Bool {
        switch diceCount {
        case 1:
            return total >= 5
        case 2:
            return total >= 9
        default:
            return total >= 13
        }
    }
}

struct LuckDiceState: Equatable, Codable, Sendable {
    var roundsRemaining: Int
    var lastFaces: [Int]

    static let empty = LuckDiceState(roundsRemaining: 0, lastFaces: [])

    var total: Int { lastFaces.reduce(0, +) }

    var lastRollIsLucky: Bool {
        guard !lastFaces.isEmpty else { return false }
        return LuckDiceRules.isLucky(total: total, diceCount: lastFaces.count)
    }
}

@MainActor
final class LuckDiceStore: ObservableObject {
    @Published private(set) var state: LuckDiceState
    /// 下一次掷出的颗数，1...3。
    @Published var diceCount: Int = 1 {
        didSet {
            let clamped = min(LuckDiceRules.maxDice, max(1, diceCount))
            if clamped != diceCount {
                diceCount = clamped
            }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: LuckDiceRules.storageKey),
           let decoded = try? JSONDecoder().decode(LuckDiceState.self, from: data) {
            state = decoded
        } else {
            state = .empty
        }
    }

    func roll() {
        let faces = (0..<diceCount).map { _ in Int.random(in: 1...6) }
        apply(faces: faces)
    }

    /// 单测注入点数。高点刷新 3 局好运；低点不取消已经在进行的好运。
    func apply(faces: [Int]) {
        let cleaned = faces
            .prefix(LuckDiceRules.maxDice)
            .map { min(6, max(1, $0)) }
        guard !cleaned.isEmpty else { return }
        var next = state
        next.lastFaces = Array(cleaned)
        if LuckDiceRules.isLucky(total: next.total, diceCount: next.lastFaces.count) {
            next.roundsRemaining = LuckDiceRules.buffRounds
        }
        state = next
        persist()
    }

    func consumeRound() {
        guard state.roundsRemaining > 0 else { return }
        state.roundsRemaining -= 1
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: LuckDiceRules.storageKey)
        }
    }
}
