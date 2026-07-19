//
//  ChipBank.swift
//  cards
//
//  阶段 3 / 3.5：筹码账户协调层。玩家余额 + 庄家池；结算委托 RoundSettlement。
//

import Foundation

/// 筹码账户：持久化双方余额与未结算注码；会话结束 / 开新游戏 / 放弃会话。
@MainActor
final class ChipBank: ObservableObject {
    @Published private(set) var balance: Int
    @Published private(set) var dealerBank: Int
    /// 已确认、尚未结算的本局下注；0 表示无进行中的注。
    @Published private(set) var activeBet: Int = 0
    @Published private(set) var lastSettlement: SettlementResult?

    private let defaults: UserDefaults
    private let storageKey: String
    private let dealerBankKey: String
    private let activeBetKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ChipRules.balanceStorageKey,
        dealerBankKey: String = ChipRules.dealerBankStorageKey,
        activeBetKey: String = ChipRules.activeBetStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.dealerBankKey = dealerBankKey
        self.activeBetKey = activeBetKey

        var loadedBalance: Int
        if defaults.object(forKey: storageKey) != nil {
            loadedBalance = max(0, defaults.integer(forKey: storageKey))
        } else {
            loadedBalance = ChipRules.startingBalance
        }

        var loadedDealer: Int
        if defaults.object(forKey: dealerBankKey) != nil {
            loadedDealer = max(0, defaults.integer(forKey: dealerBankKey))
        } else {
            loadedDealer = ChipRules.dealerStartingBank
        }

        // 进行中的注码若未结算就退出 / 杀进程，activeBet 必须退回。
        let hadActiveBetRecord = defaults.object(forKey: activeBetKey) != nil
        let orphanBet = max(0, defaults.integer(forKey: activeBetKey))
        if orphanBet > 0 {
            loadedBalance += orphanBet
        } else if !hadActiveBetRecord
            && defaults.object(forKey: dealerBankKey) == nil
            && loadedBalance < ChipRules.minimumBet {
            // 旧版只持久化扣款后余额、未记录 activeBet / 庄家池：未完成对局会被误判为破产。
            loadedBalance = ChipRules.startingBalance
            loadedDealer = ChipRules.dealerStartingBank
        }

        self.balance = loadedBalance
        self.dealerBank = loadedDealer
        self.activeBet = 0
        persist()
    }

    /// 玩家是否已无法继续最小下注（会话可能结束）。
    var isPlayerBroke: Bool {
        balance < ChipRules.minimumBet && activeBet == 0
    }

    /// 庄家池是否已掏空。
    var isDealerBroke: Bool {
        dealerBank <= 0 && activeBet == 0
    }

    /// 任一方破产则本局游戏（会话）结束。庄家优先于玩家（同时为 0 时视作打穿庄家）。
    var sessionEndReason: SessionEndReason? {
        guard activeBet == 0 else { return nil }
        if isDealerBroke { return .dealerBroke }
        if isPlayerBroke { return .playerBroke }
        return nil
    }

    var isSessionOver: Bool { sessionEndReason != nil }

    /// 当前可用于加注的上限（未确认前的草稿下注由 UI 持有）。
    var availableBalance: Int { balance }

    /// 确认下注：从余额扣出；成功返回 true。
    @discardableResult
    func placeBet(_ amount: Int) -> Bool {
        guard activeBet == 0 else { return false }
        guard !isSessionOver else { return false }
        guard amount >= ChipRules.minimumBet, amount <= balance else { return false }
        balance -= amount
        activeBet = amount
        lastSettlement = nil
        persist()
        return true
    }

    /// 对局中 All In：见牌后将剩余余额全部追加进本局注码；返回追加额，失败为 nil。
    @discardableResult
    func goAllIn() -> Int? {
        guard activeBet > 0, balance > 0 else { return nil }
        let amount = balance
        balance = 0
        activeBet += amount
        persist()
        return amount
    }

    /// 局末结算：按胜负派彩 / 退注 / 收注进庄家池；同一局不可重复结算。
    @discardableResult
    func settle(outcome: RoundOutcome) -> SettlementResult? {
        guard activeBet > 0 else { return nil }
        let result = RoundSettlement.settle(
            balanceAfterBet: balance,
            betAmount: activeBet,
            dealerBank: dealerBank,
            outcome: outcome
        )
        balance = result.balanceAfter
        dealerBank = result.dealerBankAfter
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

    /// 会话结束后开新游戏：双方重置为起始筹码（留在同副牌模式桌内）。
    func resetSession() {
        balance = ChipRules.startingBalance
        dealerBank = ChipRules.dealerStartingBank
        activeBet = 0
        lastSettlement = nil
        persist()
    }

    /// 放弃整局返回主页：清空本会话筹码状态（不写入历史；历史统计尚未实现）。
    func abandonSession() {
        resetSession()
    }

    private func persist() {
        defaults.set(balance, forKey: storageKey)
        defaults.set(dealerBank, forKey: dealerBankKey)
        defaults.set(activeBet, forKey: activeBetKey)
    }
}
