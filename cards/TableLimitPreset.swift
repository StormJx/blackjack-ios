//
//  TableLimitPreset.swift
//  cards
//
//  P4：桌限预设（最小注 + 三档筹码）；新会话开始时生效。
//

import Foundation

/// 桌限预设方案（不自由输入）。
enum TableLimitPreset: String, CaseIterable, Identifiable, Sendable {
    /// 默认：最小 100 / 档 100·200·500。
    case standard
    /// 轻量：最小 50 / 档 50·100·250。
    case light
    /// 偏大：最小 200 / 档 200·500·1000。
    case heavy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "标准"
        case .light: return "轻量"
        case .heavy: return "偏大"
        }
    }

    var minimumBet: Int {
        switch self {
        case .standard: return 100
        case .light: return 50
        case .heavy: return 200
        }
    }

    var betChipValues: [Int] {
        switch self {
        case .standard: return [100, 200, 500]
        case .light: return [50, 100, 250]
        case .heavy: return [200, 500, 1000]
        }
    }

    var summary: String {
        let chips = betChipValues.map(String.init).joined(separator: " / ")
        return "最小注 \(minimumBet)；筹码档 \(chips)"
    }
}

/// 进程内当前生效桌限；由欢迎页 / 开新会话时同步。
enum ActiveTableLimits {
    static var minimumBet: Int = TableLimitPreset.standard.minimumBet
    static var betChipValues: [Int] = TableLimitPreset.standard.betChipValues

    static func apply(_ preset: TableLimitPreset) {
        apply(minimumBet: preset.minimumBet, betChipValues: preset.betChipValues)
    }

    static func apply(minimumBet: Int, betChipValues: [Int]) {
        Self.minimumBet = minimumBet
        Self.betChipValues = betChipValues
    }
}
