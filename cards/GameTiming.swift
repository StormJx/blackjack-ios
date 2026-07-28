//
//  GameTiming.swift
//  cards
//
//  Q2：发牌 / 翻牌延迟可注入，便于单测瞬时推进。
//

import Foundation

@MainActor
protocol GameTiming {
    func sleep(nanoseconds: UInt64) async
}

/// 实机 / 模拟器：真实等待。
@MainActor
struct LiveGameTiming: GameTiming {
    func sleep(nanoseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

/// 单测：跳过全部延迟。
@MainActor
struct InstantGameTiming: GameTiming {
    func sleep(nanoseconds: UInt64) async {}
}
