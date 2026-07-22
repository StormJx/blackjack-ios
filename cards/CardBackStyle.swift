//
//  CardBackStyle.swift
//  cards
//
//  三组矢量卡背（外观奖励）；解锁 UI 后续排期，见 docs/COSMETICS_AND_PROPS.md。
//

import SwiftUI

/// 牌背样式（不影响胜负）。
enum CardBackStyle: String, CaseIterable, Identifiable, Sendable {
    /// 默认：深蓝斜纹。
    case classicNavy
    /// 翠绿格纹（奖励候选）。
    case emeraldLattice
    /// 绯红缎带（奖励候选）。
    case crimsonRibbon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicNavy: return "经典海军蓝"
        case .emeraldLattice: return "翠绿格纹"
        case .crimsonRibbon: return "绯红缎带"
        }
    }

    var unlockHint: String {
        switch self {
        case .classicNavy: return "默认拥有"
        case .emeraldLattice: return "闯关第 2 关或打穿庄家 1 次后解锁（后续开放）"
        case .crimsonRibbon: return "闯关第 3 关或累计赢 5000 后解锁（后续开放）"
        }
    }

    /// 本版仅默认样式视为已解锁；其余留给后续奖励系统。
    var isUnlockedByDefault: Bool {
        self == .classicNavy
    }
}

/// 卡背选用（持久化）；奖励解锁后续接线。
@MainActor
final class CosmeticsStore: ObservableObject {
    @Published var selectedBack: CardBackStyle {
        didSet { persist() }
    }

    @Published private(set) var unlockedBacks: Set<CardBackStyle>

    private let defaults: UserDefaults

    private enum Keys {
        static let selected = "cosmetics.selectedCardBack"
        static let unlocked = "cosmetics.unlockedCardBacks"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Keys.selected),
           let style = CardBackStyle(rawValue: raw) {
            selectedBack = style
        } else {
            selectedBack = .classicNavy
        }
        let rawUnlocked = defaults.stringArray(forKey: Keys.unlocked) ?? []
        var set = Set(rawUnlocked.compactMap(CardBackStyle.init(rawValue:)))
        set.insert(.classicNavy)
        unlockedBacks = set
        if !unlockedBacks.contains(selectedBack) {
            selectedBack = .classicNavy
        }
    }

    func owns(_ style: CardBackStyle) -> Bool {
        unlockedBacks.contains(style)
    }

    @discardableResult
    func unlock(_ style: CardBackStyle) -> Bool {
        guard !unlockedBacks.contains(style) else { return false }
        unlockedBacks.insert(style)
        persist()
        return true
    }

    func select(_ style: CardBackStyle) {
        guard owns(style) else { return }
        selectedBack = style
    }

    private func persist() {
        defaults.set(selectedBack.rawValue, forKey: Keys.selected)
        defaults.set(unlockedBacks.map(\.rawValue).sorted(), forKey: Keys.unlocked)
    }
}
