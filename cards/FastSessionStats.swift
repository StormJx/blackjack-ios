//
//  FastSessionStats.swift
//  cards
//
//  E1：快速模式本会话胜负累计（纯值类型，可单测）。
//

import Foundation

/// 娱乐模式本会话胜负累计（纯值类型，可单测；不跨会话持久化）。
struct FastSessionStats: Equatable, Sendable {
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    /// 当前连胜（平局与失败都会打断）。
    var currentWinStreak: Int = 0

    var roundsPlayed: Int { wins + losses + pushes }

    var summaryLine: String {
        L10n.format("fast.sessionSummaryFormat", wins, losses, pushes, currentWinStreak)
    }

    /// 根据本局结局更新计数与连胜。
    mutating func record(_ outcome: RoundOutcome) {
        switch outcome {
        case .playerBlackjack, .playerWin:
            wins += 1
            currentWinStreak += 1
        case .playerLose, .playerSurrender:
            losses += 1
            currentWinStreak = 0
        case .push:
            pushes += 1
            currentWinStreak = 0
        }
    }
}
