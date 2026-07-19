//
//  PracticeMode.swift
//  cards
//
//  阶段 1（v1.5）+ 阶段 2（v1.6）：一副 / 两副 / 六副练习并存；牌堆持久化与切牌重洗见 Deck。
//

import Foundation

/// 练习入口区分的玩法变体；每种变体使用同一套庄家与胜负规则，仅牌堆规模不同。
enum PracticeMode: String, CaseIterable, Identifiable, Sendable {
    /// 一副牌：52 张持久牌堆，切牌点后局间重洗。
    case singleDeck
    /// 多副牌堆：52×N 张持久牌堆，切牌点后局间重洗。
    /// 练习入口仅保留「两副 / 六副」两档：轻量多副与常见六副，避免选项过多。
    case shoe2
    case shoe6

    var id: String { rawValue }

    /// 本模式使用的完整牌张数（整副规模）。
    var numberOfDecks: Int {
        switch self {
        case .singleDeck: return 1
        case .shoe2: return 2
        case .shoe6: return 6
        }
    }

    /// 欢迎页 / 牌桌简短展示用：一副牌、两副牌、六副牌。
    var shortLabel: String {
        "\(Self.chineseDeckCount(numberOfDecks))副牌"
    }

    /// 牌桌副标题：总张数说明（剩余张数由对局层动态拼接）。
    var tableSubtitleBase: String {
        let total = numberOfDecks * 52
        return "共 \(total) 张，切牌点后重洗"
    }

    /// 欢迎页 Picker 选项文案。
    var pickerLabel: String {
        shortLabel
    }

    private static func chineseDeckCount(_ n: Int) -> String {
        switch n {
        case 1: return "一"
        case 2: return "两"
        case 6: return "六"
        default: return "\(n)"
        }
    }
}
