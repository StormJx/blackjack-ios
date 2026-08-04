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
    /// 随机将庄家一张牌洗回牌库再抽一张替换（每局限 1 次）。
    case reshuffleDealerCard

    var id: String { rawValue }

    var title: String {
        L10n.key("prop.\(rawValue).title")
    }

    var detail: String {
        L10n.key("prop.\(rawValue).detail")
    }

    var unlockHint: String {
        L10n.key("prop.\(rawValue).unlockHint")
    }

    /// 是否主要靠闯关成就解锁（娱乐页签展示「去闯关解锁」）。
    var unlocksViaChallenge: Bool {
        switch self {
        case .midHandAllIn, .dealerSoft17Hit: return true
        case .peekHole, .redrawOne, .reshuffleDealerCard: return false
        }
    }

    /// 成就 → 道具兑换映射。
    var unlockAchievement: AchievementID {
        switch self {
        case .midHandAllIn: return .dealerClear1
        case .dealerSoft17Hit: return .dealerClear5
        case .peekHole: return .practiceWinStreak5
        case .redrawOne: return .practiceWins20
        case .reshuffleDealerCard: return .practiceWins50
        }
    }
}

/// 道具持有状态（UserDefaults）；成就兑换规则见 `syncFromAchievements`。
@MainActor
final class PropStore: ObservableObject {
    @Published private(set) var ownedIDs: Set<PropID>
    /// UX6：是否已看过娱乐道具首次引导。
    @Published private(set) var hasSeenGameplayPropsGuide: Bool

    private let defaults: UserDefaults

    private enum Keys {
        static let owned = "props.owned"
        static let propsGuide = "props.didShowGameplayGuide"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.stringArray(forKey: Keys.owned) ?? []
        ownedIDs = Set(raw.compactMap(PropID.init(rawValue:)))
        hasSeenGameplayPropsGuide = defaults.bool(forKey: Keys.propsGuide)
        _ = syncFromAchievementRawValues(defaults.stringArray(forKey: "stats.unlockedAchievements") ?? [])
    }

    func owns(_ id: PropID) -> Bool {
        ownedIDs.contains(id)
    }

    /// 娱乐会话开局：已有道具且未看过引导时提示。
    var needsGameplayPropsGuide: Bool {
        !hasSeenGameplayPropsGuide && !ownedIDs.isEmpty
    }

    func acknowledgeGameplayPropsGuide() {
        guard !hasSeenGameplayPropsGuide else { return }
        hasSeenGameplayPropsGuide = true
        defaults.set(true, forKey: Keys.propsGuide)
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
