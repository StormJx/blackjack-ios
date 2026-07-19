//
//  ChipRules.swift
//  cards
//
//  阶段 3（v1.7）：筹码与赔率常量。与 VERSION_ROADMAP「筹码与赔率」锁定决策一致。
//

import Foundation

/// 桌面经济规则（纯常量，无状态）。
enum ChipRules {
    /// 起始筹码 / 一键补码目标。
    static let startingBalance = 1000

    /// 最小下注。
    static let minimumBet = 10

    /// 下注页筹码面额：从 0 累加；单次累加后总注不得超过余额。
    static let betChipValues = [10, 25, 50, 100, 200]

    /// 普通 All In：余额须严格大于该值（等于起始筹码时开局不可 All In，降低一局梭哈的波动）。
    static let allInUnlockBalance = startingBalance

    /// 一副牌「强制 All In」触发：本局实际开打前剩余张数 ≤ 该值（且不会先重洗）。
    static let forcedAllInRemainingCards = 15

    /// UserDefaults 键：持久化余额。
    static let balanceStorageKey = "chipBank.balance"

    /// UserDefaults 键：尚未结算的本局注码（用于杀进程 / 异常退出后退注）。
    static let activeBetStorageKey = "chipBank.activeBet"

    /// 普通 All In 是否可用（与牌堆无关）。
    static func canUseStandardAllIn(balance: Int) -> Bool {
        balance > allInUnlockBalance
    }

    /// 一副牌残局「强制 All In」入口是否应出现。
    /// - Note: `willReshuffle` 为 true 时本局会先重洗，剩余张数不再是开局牌况，故不展示。
    static func canUseForcedAllIn(
        isSingleDeck: Bool,
        remainingCards: Int,
        willReshuffle: Bool
    ) -> Bool {
        isSingleDeck
            && remainingCards > 0
            && remainingCards <= forcedAllInRemainingCards
            && !willReshuffle
    }

    /// 黑杰克赔率文案（结算 UI 与结果区共用）。
    static let blackjackOddsLabel = "黑杰克赔率 3:2"

    /// 普通获胜赔率文案。
    static let evenMoneyOddsLabel = "普通胜负 1:1"

    /// 黑杰克净赢：下注 × 3/2（整数向下取整）。本金另计退还。
    static func blackjackProfit(forBet bet: Int) -> Int {
        (bet * 3) / 2
    }

    /// 普通获胜净赢：1:1。
    static func evenMoneyProfit(forBet bet: Int) -> Int {
        bet
    }
}
