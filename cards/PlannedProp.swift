//
//  PlannedProp.swift
//  cards
//
//  规划中的玩法道具（尚未接线效果）；供成就页 / 文档对照。
//

import Foundation

/// 规划中的玩法道具（未实现效果）。
enum PlannedPropID: String, CaseIterable, Identifiable {
    /// 随机将庄家一张牌洗回牌库，再抽一张替换（仅娱乐）。
    case reshuffleDealerCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reshuffleDealerCard: return "换庄家一张"
        }
    }

    var detail: String {
        switch self {
        case .reshuffleDealerCard:
            return "仅娱乐（规划）：随机将庄家手牌中一张洗回牌库，再抽一张替换。规则与动画待锁。"
        }
    }

    var unlockHint: String {
        switch self {
        case .reshuffleDealerCard:
            return "解锁条件待定（建议：娱乐胜场或打穿阶梯）"
        }
    }
}
