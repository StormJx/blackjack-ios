//
//  ChipBank.swift
//  cards
//
//  阶段 3 / 3.5：筹码账户协调层。玩家余额 + 庄家池；结算委托 RoundSettlement。
//

import Foundation

/// 筹码账户：持久化双方余额与未结算注码；会话结束回主页 / 放弃会话。
@MainActor
final class ChipBank: ObservableObject {
    @Published private(set) var balance: Int
    @Published private(set) var dealerBank: Int
    /// 已确认、尚未结算的本局下注；0 表示无进行中的注。
    @Published private(set) var activeBet: Int = 0
    @Published private(set) var lastSettlement: SettlementResult?
    /// 启动时因杀进程等退回了未结算注码；供 UI 提示一次（与主动「退出清空」相对）。
    @Published private(set) var didRestoreAfterInterrupt: Bool = false
    /// 当前 / 刚结束的一局注码是否为全下（开局梭哈或对局中追加至全部余额）。
    private(set) var activeBetWasAllIn: Bool = false

    private let defaults: UserDefaults
    private let storageKey: String
    private let dealerBankKey: String
    private let activeBetKey: String
    /// 本会话重置目标（闯关按关卡；娱乐用默认桌限）。
    private let sessionStartingBalance: Int
    private let sessionDealerStartingBank: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ChipRules.balanceStorageKey,
        dealerBankKey: String = ChipRules.dealerBankStorageKey,
        activeBetKey: String = ChipRules.activeBetStorageKey,
        startingBalance: Int = ChipRules.startingBalance,
        dealerStartingBank: Int = ChipRules.dealerStartingBank,
        forceFreshSession: Bool = false
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.dealerBankKey = dealerBankKey
        self.activeBetKey = activeBetKey
        self.sessionStartingBalance = startingBalance
        self.sessionDealerStartingBank = dealerStartingBank

        if forceFreshSession {
            defaults.removeObject(forKey: storageKey)
            defaults.removeObject(forKey: dealerBankKey)
            defaults.removeObject(forKey: activeBetKey)
        }

        var loadedBalance: Int
        if defaults.object(forKey: storageKey) != nil {
            loadedBalance = max(0, defaults.integer(forKey: storageKey))
        } else {
            loadedBalance = startingBalance
        }

        var loadedDealer: Int
        if defaults.object(forKey: dealerBankKey) != nil {
            loadedDealer = max(0, defaults.integer(forKey: dealerBankKey))
        } else {
            loadedDealer = dealerStartingBank
        }

        let hadActiveBetRecord = defaults.object(forKey: activeBetKey) != nil
        let orphanBet = max(0, defaults.integer(forKey: activeBetKey))
        var restoredInterrupt = false
        if orphanBet > 0 {
            loadedBalance += orphanBet
            restoredInterrupt = true
        } else if !hadActiveBetRecord
            && defaults.object(forKey: dealerBankKey) == nil
            && loadedBalance < ChipRules.minimumBet {
            loadedBalance = startingBalance
            loadedDealer = dealerStartingBank
        }

        self.balance = loadedBalance
        self.dealerBank = loadedDealer
        self.activeBet = 0
        self.didRestoreAfterInterrupt = restoredInterrupt
        persist()
    }

    func acknowledgeRestoreHint() {
        didRestoreAfterInterrupt = false
    }

    var isPlayerBroke: Bool {
        balance < ChipRules.minimumBet && activeBet == 0
    }

    var isDealerBroke: Bool {
        dealerBank <= 0 && activeBet == 0
    }

    var sessionEndReason: SessionEndReason? {
        guard activeBet == 0 else { return nil }
        if isDealerBroke { return .dealerBroke }
        if isPlayerBroke { return .playerBroke }
        return nil
    }

    var isSessionOver: Bool { sessionEndReason != nil }

    var availableBalance: Int { balance }

    @discardableResult
    func placeBet(_ amount: Int) -> Bool {
        guard activeBet == 0 else { return false }
        guard !isSessionOver else { return false }
        guard amount >= ChipRules.minimumBet, amount <= balance else { return false }
        activeBetWasAllIn = (amount == balance)
        balance -= amount
        activeBet = amount
        lastSettlement = nil
        persist()
        return true
    }

    /// 对局中 All In；门控：娱乐模式 + 道具。开局全下请用 `placeBet(balance)`。
    @discardableResult
    func goAllIn() -> Int? {
        guard activeBet > 0, balance > 0 else { return nil }
        let amount = balance
        balance = 0
        activeBet += amount
        activeBetWasAllIn = true
        persist()
        return amount
    }

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

    func refundActiveBet() {
        guard activeBet > 0 else { return }
        balance += activeBet
        activeBet = 0
        activeBetWasAllIn = false
        lastSettlement = nil
        persist()
    }

    func resetSession() {
        balance = sessionStartingBalance
        dealerBank = sessionDealerStartingBank
        activeBet = 0
        activeBetWasAllIn = false
        lastSettlement = nil
        // 清除持久化，便于下次按新关卡起始筹码建会话；杀进程中途恢复仍依赖未 clear 的键。
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: dealerBankKey)
        defaults.removeObject(forKey: activeBetKey)
    }

    func abandonSession() {
        resetSession()
    }

    private func persist() {
        defaults.set(balance, forKey: storageKey)
        defaults.set(dealerBank, forKey: dealerBankKey)
        defaults.set(activeBet, forKey: activeBetKey)
    }
}
