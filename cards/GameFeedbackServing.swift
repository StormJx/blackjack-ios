//
//  GameFeedbackServing.swift
//  cards
//
//  Q2：BlackjackGame 反馈依赖可注入；单测用静默实现。
//

import Foundation

@MainActor
protocol GameFeedbackServing: AnyObject {
    func notifyError()
    func cardDealt()
    func holeRevealed()
    func shuffleHint()
    func roundOutcome(playerWon: Bool?, isPush: Bool)
}

extension GameFeedback: GameFeedbackServing {}

/// 单测：不播音效、不触发触觉。
@MainActor
final class SilentGameFeedback: GameFeedbackServing {
    func notifyError() {}
    func cardDealt() {}
    func holeRevealed() {}
    func shuffleHint() {}
    func roundOutcome(playerWon: Bool?, isPush: Bool) {}
}
