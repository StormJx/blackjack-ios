//
//  FirstSessionGuide.swift
//  cards
//
//  首局引导：各模式第一次下注页一句目标；看过或确认发牌后不再出现。
//

import Foundation

enum FirstSessionGuide {
    static func goalLine(playStyle: PlayStyle, dealerStart: Int) -> String {
        switch playStyle {
        case .challenge:
            return L10n.format("guide.first.challengeFormat", dealerStart)
        case .entertainment:
            return L10n.format("guide.first.entertainmentFormat", dealerStart)
        }
    }
}
