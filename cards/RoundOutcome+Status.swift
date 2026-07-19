//
//  RoundOutcome+Status.swift
//  cards
//
//  D12：结局着色 / 图标由 RoundOutcome 驱动，勿解析 outcomeMessage。
//

import SwiftUI

extension RoundOutcome {
    var statusColor: Color {
        switch self {
        case .playerBlackjack, .playerWin:
            return .green
        case .playerLose:
            return .red
        case .push:
            return .orange
        }
    }
}
