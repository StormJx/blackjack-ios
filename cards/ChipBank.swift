//
//  ChipBank.swift
//  cards
//
//  阶段 3（v1.7）：筹码账户协调层。持有余额与本局注码；结算委托 RoundSettlement。
//

import Foundation

/// 筹码账户：持久化余额、下注扣款、局末结算、破产补码。
@MainActor
final class ChipBank: ObservableObject {
    @Published private(set) var balance: Int
    /// 已确认、尚未结算的本局下注；0 表示无进行中的注。
    @Published private(set) var activeBet: Int = 0
    @Published private(set) var lastSettlement: SettlementResult?

    private let defaults: UserDefaults
    private let storageKey: String
    private let activeBetKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ChipRules.balanceStorageKey,
        activeBetKey: String = ChipRules.activeBetStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.activeBetKey = activeBetKey

        // 首次无记录 → 起始筹码；否则读取已存余额（避免 `as? Int` 桥接失败误判）。
        var loadedBalance: Int
        if defaults.object(forKey: storageKey) != nil {
            loadedBalance = max(0, defaults.integer(forKey: storageKey))
        } else {
            loadedBalance = ChipRules.startingBalance
        }

        // 进行中的注码若未结算就退出 / 杀进程，activeBet 必须退回，否则会出现「一开局就要补码」。
        let hadActiveBetRecord = defaults.object(forKey: activeBetKey) != nil
        let orphanBet = max(0, defaults.integer(forKey: activeBetKey))
        if orphanBet > 0 {
            loadedBalance += orphanBet
        } else if !hadActiveBetRecord && loadedBalance < ChipRules.minimumBet {
            // 旧版只持久化扣款后余额、未记录 activeBet：未完成对局会被误判为破产。
            loadedBalance = ChipRules.startingBalance
        }

        self.balance = loadedBalance
        self.activeBet = 0
        persist()
    }

    /// 余额不足以最小下注时需补码。
    var needsRefill: Bool {
        balance < ChipRules.minimumBet && activeBet == 0
    }

    /// 当前可用于加注的上限（未确认前的草稿下注由 UI 持有）。
    var availableBalance: Int { balance }

    /// 确认下注：从余额扣出；成功返回 true。
    @discardableResult
    func placeBet(_ amount: Int) -> Bool {
        guard activeBet == 0 else { return false }
        guard amount >= ChipRules.minimumBet, amount <= balance else { return false }
        balance -= amount
        activeBet = amount
        lastSettlement = nil
        persist()
        return true
    }

    /// 局末结算：按胜负派彩 / 退注；同一局不可重复结算。
    @discardableResult
    func settle(outcome: RoundOutcome) -> SettlementResult? {
        guard activeBet > 0 else { return nil }
        let result = RoundSettlement.settle(
            balanceAfterBet: balance,
            betAmount: activeBet,
            outcome: outcome
        )
        balance = result.balanceAfter
        activeBet = 0
        lastSettlement = result
        persist()
        return result
    }

    /// 发牌异常、返回模式选择、进程中断恢复：退回未结算的本局下注（不产生盈亏记录）。
    func refundActiveBet() {
        guard activeBet > 0 else { return }
        balance += activeBet
        activeBet = 0
        lastSettlement = nil
        persist()
    }

    /// 破产一键补至起始筹码。
    func refillToStartingBalance() {
        guard needsRefill else { return }
        balance = ChipRules.startingBalance
        lastSettlement = nil
        persist()
    }

    private func persist() {
        defaults.set(balance, forKey: storageKey)
        defaults.set(activeBet, forKey: activeBetKey)
    }
}
