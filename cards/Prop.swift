//
//  Prop.swift
//  cards
//
//  玩法道具：仅娱乐模式可用。见 docs/COSMETICS_AND_PROPS.md。
//

import Foundation
import SwiftUI

/// 已实现的玩法道具。
enum PropID: String, CaseIterable, Identifiable {
    /// 对局中见牌后再全下（复用 `ChipBank.goAllIn` + 牌桌「全下」键）。
    case midHandAllIn
    /// 本局庄家软 17 必须要牌。
    case dealerSoft17Hit
    /// 玩家回合偷看庄家暗牌约 1 秒（每局限 1 次）。
    case peekHole
    /// 换掉最近一次要牌得到的牌（每局限 1 次）。
    case redrawOne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midHandAllIn: return "见牌后再全下"
        case .dealerSoft17Hit: return "庄家软 17 要牌"
        case .peekHole: return "窥视暗牌"
        case .redrawOne: return "换一张"
        }
    }

    var detail: String {
        switch self {
        case .midHandAllIn:
            return "仅娱乐模式：对局中可将剩余筹码追加为全下并自动停牌。闯关模式不可用。天然黑杰克见牌即结算时不可用。"
        case .dealerSoft17Hit:
            return "仅娱乐模式：玩家回合开启后，本局庄家软 17 必须要牌。下局需再开。"
        case .peekHole:
            return "仅娱乐模式：玩家回合偷看庄家暗牌约 1 秒，每局限 1 次。"
        case .redrawOne:
            return "仅娱乐模式：弃掉最近一次要牌得到的牌并重发一张（须已要过牌）。每局限 1 次；天然 BJ 不可用。"
        }
    }

    var unlockHint: String {
        switch self {
        case .midHandAllIn:
            return "打穿庄家资金池 1 次后永久解锁（仅娱乐可用）"
        case .dealerSoft17Hit:
            return "打穿庄家资金池 5 次后永久解锁（仅娱乐可用）"
        case .peekHole:
            return "娱乐模式连胜达 5 后永久解锁"
        case .redrawOne:
            return "娱乐模式累计胜 20 局后永久解锁"
        }
    }

    /// 成就 → 道具兑换映射。
    var unlockAchievement: AchievementID {
        switch self {
        case .midHandAllIn: return .dealerClear1
        case .dealerSoft17Hit: return .dealerClear5
        case .peekHole: return .practiceWinStreak5
        case .redrawOne: return .practiceWins20
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

    /// 成就 → 道具兑换（永久解锁；仍仅娱乐模式可使用）。
    @discardableResult
    func syncFromAchievements(_ unlocked: Set<AchievementID>) -> [PropID] {
        var newly: [PropID] = []
        for prop in PropID.allCases {
            if unlocked.contains(prop.unlockAchievement), unlock(prop) {
                newly.append(prop)
            }
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
