//
//  Prop.swift
//  cards
//
//  玩法道具：仅娱乐模式可用。规划项见 docs/COSMETICS_AND_PROPS.md。
//

import Foundation
import SwiftUI

/// 已实现的玩法道具。
enum PropID: String, CaseIterable, Identifiable {
    /// 对局中见牌后再全下（复用 `ChipBank.goAllIn` + 牌桌「全下」键）。
    case midHandAllIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midHandAllIn: return "见牌后再全下"
        }
    }

    var detail: String {
        switch self {
        case .midHandAllIn:
            return "仅娱乐模式：对局中可将剩余筹码追加为全下并自动停牌。闯关模式不可用。天然黑杰克见牌即结算时不可用。"
        }
    }

    var unlockHint: String {
        switch self {
        case .midHandAllIn:
            return "打穿庄家资金池 1 次后永久解锁（仅娱乐可用）"
        }
    }
}

/// 规划中的玩法道具 ID（尚未实现效果；供文档与后续接线对照）。
enum PlannedPropID: String, CaseIterable, Identifiable {
    case peekHole
    case dealerSoft17Hit
    case redrawOne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .peekHole: return "窥视暗牌"
        case .dealerSoft17Hit: return "庄家软 17 要牌"
        case .redrawOne: return "换一张"
        }
    }

    var detail: String {
        switch self {
        case .peekHole:
            return "玩家回合偷看庄家暗牌约 1 秒（建议每局限 1 次）。仅娱乐。"
        case .dealerSoft17Hit:
            return "本局庄家软 17 必须要牌。仅娱乐。"
        case .redrawOne:
            return "弃掉自己一张牌并重发一张（天然 BJ 起手除外）。仅娱乐。"
        }
    }
}

/// 道具持有状态（UserDefaults）；成就兑换规则见 `syncFromAchievements`。
@MainActor
final class PropStore: ObservableObject {
    @Published private(set) var ownedIDs: Set<PropID>

    private let defaults: UserDefaults

    private enum Keys {
        static let owned = "props.owned"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.stringArray(forKey: Keys.owned) ?? []
        ownedIDs = Set(raw.compactMap(PropID.init(rawValue:)))
        _ = syncFromAchievementRawValues(defaults.stringArray(forKey: "stats.unlockedAchievements") ?? [])
    }

    func owns(_ id: PropID) -> Bool {
        ownedIDs.contains(id)
    }

    /// 是否可在当前玩法下使用（持有 + 模式允许）。
    func canUse(_ id: PropID, in style: PlayStyle) -> Bool {
        style.allowsGameplayProps && owns(id)
    }

    @discardableResult
    func unlock(_ id: PropID) -> Bool {
        guard !ownedIDs.contains(id) else { return false }
        ownedIDs.insert(id)
        persist()
        return true
    }

    /// 成就 → 道具兑换：`dealerClear1` → 永久 `midHandAllIn`（仍仅娱乐模式可使用）。
    @discardableResult
    func syncFromAchievements(_ unlocked: Set<AchievementID>) -> [PropID] {
        var newly: [PropID] = []
        if unlocked.contains(.dealerClear1), unlock(.midHandAllIn) {
            newly.append(.midHandAllIn)
        }
        return newly
    }

    @discardableResult
    func syncFromAchievementRawValues(_ raw: [String]) -> [PropID] {
        let unlocked = Set(raw.compactMap(AchievementID.init(rawValue:)))
        return syncFromAchievements(unlocked)
    }

    private func persist() {
        defaults.set(ownedIDs.map(\.rawValue).sorted(), forKey: Keys.owned)
    }
}
