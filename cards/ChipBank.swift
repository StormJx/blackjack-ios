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

        // 进行中的注码若未结算就杀进程 / 异常退出：退回注码并保留双方进度（非主动退出清空）。
        let hadActiveBetRecord = defaults.object(forKey: activeBetKey) != nil
        let orphanBet = max(0, defaults.integer(forKey: activeBetKey))
        var restoredInterrupt = false
        if orphanBet > 0 {
            loadedBalance += orphanBet
            restoredInterrupt = true
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
        self.didRestoreAfterInterrupt = restoredInterrupt
        persist()
    }

    /// UI 已展示恢复提示后清除，避免重复打扰。
    func acknowledgeRestoreHint() {
        didRestoreAfterInterrupt = false
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
        activeBetWasAllIn = (amount == balance)
        balance -= amount
        activeBet = amount
        lastSettlement = nil
        persist()
        return true
    }

    /// 对局中 All In（道具预留）：见牌后将剩余余额全部追加进本局注码；返回追加额，失败为 nil。
    /// 默认练习关闭（`ChipRules.midHandAllInEnabled == false`）；开局全下请用 `placeBet(balance)`。
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
        activeBetWasAllIn = false
        lastSettlement = nil
        persist()
    }

    /// 清空本会话筹码至起始状态（破产回主页 / 主动退出共用）。
    func resetSession() {
        balance = ChipRules.startingBalance
        dealerBank = ChipRules.dealerStartingBank
        activeBet = 0
        activeBetWasAllIn = false
        lastSettlement = nil
        persist()
    }

    /// 结束会话返回主页：清空筹码状态。
    func abandonSession() {
        resetSession()
    }

    private func persist() {
        defaults.set(balance, forKey: storageKey)
        defaults.set(dealerBank, forKey: dealerBankKey)
        defaults.set(activeBet, forKey: activeBetKey)
    }
}
