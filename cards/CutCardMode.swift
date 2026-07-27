//
//  CutCardMode.swift
//  cards
//
//  P5：闯关切牌三态（每局重洗 / 仪式感 / 真实渗透）。
//

import Foundation

/// 切牌策略（设置页三选一；娱乐模式会话内固定为 `.real`）。
enum CutCardMode: String, CaseIterable, Identifiable, Sendable {
    /// 每局打完后下一局必整副重洗（无渗透）。
    case off
    /// 仪式感：洗牌页仍展示切牌文案，但不按切牌点强制重洗；打到不足开局四张才重洗。
    case ceremonial
    /// 真实渗透：切牌点约在总牌数 50%–75%，达点后局间重洗（含尾牌例外）。
    case real

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "每局重洗"
        case .ceremonial: return "仪式感切牌"
        case .real: return "真实切牌"
        }
    }

    var settingsDetail: String {
        switch self {
        case .off:
            return "闯关：每局打完下一局必整副重洗（无渗透）。"
        case .ceremonial:
            return "闯关：洗牌页保留切牌仪式文案，但不按切牌点强制重洗；牌堆打到不足开局四张才重洗。"
        case .real:
            return "闯关：按 50%–75% 切牌点局间重洗（含尾牌 4–6 张打完再洗）。"
        }
    }

    /// 是否按切牌点做渗透重洗数学。
    var usesPenetrationMath: Bool { self == .real }

    /// 洗牌页是否使用切牌相关文案。
    var showsCutRitualCopy: Bool { self == .real || self == .ceremonial }

    var shuffleOverlayDetail: String {
        switch self {
        case .off:
            return "本局已结束，正在重新整理牌堆"
        case .ceremonial:
            return "仪式切牌完成，正在重新整理牌堆"
        case .real:
            return "切牌点已过，正在重新整理牌堆"
        }
    }
}
