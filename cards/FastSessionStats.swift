//
//  FastSessionStats.swift
//  cards
//
//  E1：快速模式本会话胜负累计（纯值类型，可单测）。
//

import Foundation

/// 娱乐模式会话内统计；不跨会话持久化。
struct FastSessionStats: Equatable, Sendable {
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    /// 当前连胜（平局与失败都会打断）。
    var currentWinStreak: Int = 0

    var roundsPlayed: Int { wins + losses + pushes }

    var summaryLine: String {
        "本会话 \(wins) 胜 · \(losses) 负 · \(pushes) 平 · 连胜 \(currentWinStreak)"
    }

    /// 根据本局结局更新计数与连胜。
    mutating func record(_ outcome: RoundOutcome) {
        switch outcome {
        case .playerBlackjack, .playerWin:
            wins += 1
            currentWinStreak += 1
        case .playerLose:
            losses += 1
            currentWinStreak = 0
        case .push:
            pushes += 1
            currentWinStreak = 0
        }
    }
}
