//
//  CardBackStyle.swift
//  cards
//
//  三组矢量卡背（外观奖励）；解锁与选用见设置页 / docs/COSMETICS_AND_PROPS.md。
//

import SwiftUI

/// 牌背样式（不影响胜负）。
enum CardBackStyle: String, CaseIterable, Identifiable, Sendable {
    /// 默认：深蓝斜纹。
    case classicNavy
    /// 翠绿格纹（奖励）。
    case emeraldLattice
    /// 绯红缎带（奖励）。
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
        case .emeraldLattice: return "闯关第 2 关或打穿庄家 1 次后解锁"
        case .crimsonRibbon: return "闯关第 3 关或累计赢 5000 后解锁"
        }
    }

    /// 本版仅默认样式视为已解锁；其余由进度同步。
    var isUnlockedByDefault: Bool {
        self == .classicNavy
    }

    /// 是否满足解锁条件（仅用闯关轨战绩 / 关卡）。
    func isEligible(
        unlockedLevel: Int,
        dealerClears: Int,
        totalChipsWon: Int
    ) -> Bool {
        switch self {
        case .classicNavy:
            return true
        case .emeraldLattice:
            return unlockedLevel >= 2 || dealerClears >= 1
        case .crimsonRibbon:
            return unlockedLevel >= 3 || totalChipsWon >= 5000
        }
    }
}

/// 卡背选用与解锁（持久化）。
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

    /// 按闯关进度同步卡背解锁；返回本轮新解锁列表。
    @discardableResult
    func syncFromProgress(
        unlockedLevel: Int,
        dealerClears: Int,
        totalChipsWon: Int
    ) -> [CardBackStyle] {
        var newly: [CardBackStyle] = []
        for style in CardBackStyle.allCases {
            guard style.isEligible(
                unlockedLevel: unlockedLevel,
                dealerClears: dealerClears,
                totalChipsWon: totalChipsWon
            ) else { continue }
            if unlock(style) {
                newly.append(style)
            }
        }
        return newly
    }

    private func persist() {
        defaults.set(selectedBack.rawValue, forKey: Keys.selected)
        defaults.set(unlockedBacks.map(\.rawValue).sorted(), forKey: Keys.unlocked)
    }
}
