//
//  ChipBank.swift
//  cards
//
//  阶段 3 / 3.5：筹码账户协调层。玩家余额 + 庄家池；结算委托 RoundSettlement。
//  Q1：本会话全下解锁局数与筹码同 suite 持久化。
//  P6+：保险侧注（activeInsurance）与主注一并持久化 / 中断退回。
//

import Foundation

/// 筹码账户：持久化双方余额与未结算注码；会话结束回主页 / 放弃会话。
@MainActor
final class ChipBank: ObservableObject {
    @Published private(set) var balance: Int
    @Published private(set) var dealerBank: Int
    /// 已确认、尚未结算的本局下注；0 表示无进行中的注。
    @Published private(set) var activeBet: Int = 0
    /// P6+：已扣出、尚未结算的保险侧注。
    @Published private(set) var activeInsurance: Int = 0
    /// L2：分牌第二手未结算注码。第一手仍用 `activeBet`。
    @Published private(set) var splitSecondBet: Int = 0
    @Published private(set) var lastSettlement: SettlementResult?
    /// 启动时因杀进程等退回了未结算注码；供 UI 提示一次（与主动「退出清空」相对）。
    @Published private(set) var didRestoreAfterInterrupt: Bool = false
    /// 本会话已完成局数（开局全下解锁）；与筹码一并持久化，杀进程后保留。
    @Published private(set) var sessionRoundsCompleted: Int = 0
    /// 当前 / 刚结束的一局注码是否为全下（开局梭哈或对局中追加至全部余额）。
    private(set) var activeBetWasAllIn: Bool = false

    private let defaults: UserDefaults
    private let storageKey: String
    private let dealerBankKey: String
    private let activeBetKey: String
    private let activeInsuranceKey: String
    private let splitSecondBetKey: String
    private let sessionRoundsKey: String
    /// 本会话重置目标（闯关按关卡；娱乐用默认桌限）。
    private let sessionStartingBalance: Int
    private let sessionDealerStartingBank: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ChipRules.balanceStorageKey,
        dealerBankKey: String = ChipRules.dealerBankStorageKey,
        activeBetKey: String = ChipRules.activeBetStorageKey,
        activeInsuranceKey: String = ChipRules.activeInsuranceStorageKey,
        splitSecondBetKey: String = ChipRules.splitSecondBetStorageKey,
        sessionRoundsKey: String = ChipRules.sessionRoundsStorageKey,
        startingBalance: Int = ChipRules.startingBalance,
        dealerStartingBank: Int = ChipRules.dealerStartingBank,
        forceFreshSession: Bool = false
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.dealerBankKey = dealerBankKey
        self.activeBetKey = activeBetKey
        self.activeInsuranceKey = activeInsuranceKey
        self.splitSecondBetKey = splitSecondBetKey
        self.sessionRoundsKey = sessionRoundsKey
        self.sessionStartingBalance = startingBalance
        self.sessionDealerStartingBank = dealerStartingBank

        if forceFreshSession {
            defaults.removeObject(forKey: storageKey)
            defaults.removeObject(forKey: dealerBankKey)
            defaults.removeObject(forKey: activeBetKey)
            defaults.removeObject(forKey: activeInsuranceKey)
            defaults.removeObject(forKey: splitSecondBetKey)
            defaults.removeObject(forKey: sessionRoundsKey)
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
        let orphanInsurance = max(0, defaults.integer(forKey: activeInsuranceKey))
        let orphanSplit = max(0, defaults.integer(forKey: splitSecondBetKey))
        var restoredInterrupt = false
        if orphanBet > 0 || orphanInsurance > 0 || orphanSplit > 0 {
            loadedBalance += orphanBet + orphanInsurance + orphanSplit
            restoredInterrupt = true
        } else if !hadActiveBetRecord
            && defaults.object(forKey: dealerBankKey) == nil
            && loadedBalance < ChipRules.minimumBet {
            loadedBalance = startingBalance
            loadedDealer = dealerStartingBank
        }

        let loadedRounds: Int
        if defaults.object(forKey: sessionRoundsKey) != nil {
            loadedRounds = max(0, defaults.integer(forKey: sessionRoundsKey))
        } else {
            loadedRounds = 0
        }

        self.balance = loadedBalance
        self.dealerBank = loadedDealer
        self.activeBet = 0
        self.activeInsurance = 0
        self.splitSecondBet = 0
        self.sessionRoundsCompleted = loadedRounds
        self.didRestoreAfterInterrupt = restoredInterrupt
        persist()
    }

    func acknowledgeRestoreHint() {
        didRestoreAfterInterrupt = false
    }

    /// 一局结算完成后递增（含天然 BJ / 正常比点）；与筹码一并写入磁盘。
    func recordRoundCompleted() {
        sessionRoundsCompleted += 1
        persist()
    }

    private var hasUnsettledStake: Bool {
        activeBet > 0 || splitSecondBet > 0
    }

    var isPlayerBroke: Bool {
        balance < ChipRules.minimumBet && !hasUnsettledStake
    }

    var isDealerBroke: Bool {
        dealerBank <= 0 && !hasUnsettledStake
    }

    var sessionEndReason: SessionEndReason? {
        guard !hasUnsettledStake else { return nil }
        if isDealerBroke { return .dealerBroke }
        if isPlayerBroke { return .playerBroke }
        return nil
    }

    var isSessionOver: Bool { sessionEndReason != nil }

    var availableBalance: Int { balance }

    /// 可买保险：已有主注、非全下、尚未买过、余额 ≥ 半注。
    var canAffordInsurance: Bool {
        guard activeBet > 0, activeInsurance == 0, !activeBetWasAllIn else { return false }
        let amount = ChipRules.insuranceBetAmount(forMainBet: activeBet)
        return amount > 0 && balance >= amount
    }

    /// VoiceOver / 按钮：保险不可用原因（可买时为 nil）。
    var insuranceDisabledReason: String? {
        if canAffordInsurance { return nil }
        if activeBet == 0 { return L10n.t("insurance.disabled.noBet") }
        if activeBetWasAllIn { return L10n.t("insurance.disabled.allIn") }
        if activeInsurance > 0 { return L10n.t("insurance.disabled.already") }
        let amount = ChipRules.insuranceBetAmount(forMainBet: activeBet)
        if amount <= 0 { return L10n.t("insurance.disabled.betTooSmall") }
        if balance < amount { return L10n.t("insurance.disabled.insufficient") }
        return L10n.t("insurance.disabled.unavailable")
    }

    @discardableResult
    func placeBet(_ amount: Int) -> Bool {
        guard activeBet == 0 else { return false }
        guard !isSessionOver else { return false }
        guard amount >= ChipRules.minimumBet, amount <= balance else { return false }
        activeBetWasAllIn = (amount == balance)
        balance -= amount
        activeBet = amount
        activeInsurance = 0
        lastSettlement = nil
        persist()
        return true
    }

    /// P6+：买入保险（半注，向下取整）。
    @discardableResult
    func placeInsurance() -> Bool {
        guard canAffordInsurance else { return false }
        let amount = ChipRules.insuranceBetAmount(forMainBet: activeBet)
        balance -= amount
        activeInsurance = amount
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

    /// 是否可足额加倍：须已有注码，且余额 ≥ 当前注（不足则禁用，不做不足额加倍）。
    var canAffordDoubleDown: Bool {
        activeBet > 0 && balance >= activeBet
    }

    /// 可分牌：再押一注等额，且本局不是全下。
    var canBeginSplit: Bool {
        activeBet > 0 && splitSecondBet == 0 && !activeBetWasAllIn && balance >= activeBet
    }

    /// L2：扣出与第一手相同的第二注。全下或余额不足时失败。
    @discardableResult
    func beginSplit() -> Bool {
        guard canBeginSplit else { return false }
        balance -= activeBet
        splitSecondBet = activeBet
        persist()
        return true
    }

    /// 加倍分牌第二手。第一手仍走 `doubleDown()`。
    @discardableResult
    func doubleSplitSecondHand() -> Bool {
        guard splitSecondBet > 0, balance >= splitSecondBet else { return false }
        let extra = splitSecondBet
        balance -= extra
        splitSecondBet += extra
        persist()
        return true
    }

    /// P6：加倍——再押与当前注等额；余额归零也不记为全下（`activeBetWasAllIn` 不变）。
    @discardableResult
    func doubleDown() -> Bool {
        guard canAffordDoubleDown else { return false }
        let amount = activeBet
        balance -= amount
        activeBet += amount
        persist()
        return true
    }

    /// - Parameter insuranceWon: 庄家黑杰克且本局已买保险时为 true。
    @discardableResult
    func settle(outcome: RoundOutcome, insuranceWon: Bool = false) -> SettlementResult? {
        guard activeBet > 0 else { return nil }
        let result = RoundSettlement.settle(
            balanceAfterBet: balance,
            betAmount: activeBet,
            dealerBank: dealerBank,
            outcome: outcome,
            insuranceBet: activeInsurance,
            insuranceWon: insuranceWon && activeInsurance > 0
        )
        balance = result.balanceAfter
        dealerBank = result.dealerBankAfter
        activeBet = 0
        activeInsurance = 0
        splitSecondBet = 0
        lastSettlement = result
        persist()
        return result
    }

    /// 分牌两手分别结算后再汇总成一条局末结果。保险只跟在第一手。
    @discardableResult
    func settleSplit(first: RoundOutcome, second: RoundOutcome, insuranceWon: Bool = false) -> SettlementResult? {
        guard activeBet > 0, splitSecondBet > 0 else { return nil }
        let firstResult = RoundSettlement.settle(
            balanceAfterBet: balance,
            betAmount: activeBet,
            dealerBank: dealerBank,
            outcome: first,
            insuranceBet: activeInsurance,
            insuranceWon: insuranceWon && activeInsurance > 0
        )
        let secondResult = RoundSettlement.settle(
            balanceAfterBet: firstResult.balanceAfter,
            betAmount: splitSecondBet,
            dealerBank: firstResult.dealerBankAfter,
            outcome: second
        )
        let combined = SettlementResult(
            betAmount: firstResult.betAmount + secondResult.betAmount,
            outcome: Self.combinedSplitOutcome(first, second),
            netChange: firstResult.netChange + secondResult.netChange,
            amountReturned: firstResult.amountReturned + secondResult.amountReturned,
            balanceAfter: secondResult.balanceAfter,
            dealerBankAfter: secondResult.dealerBankAfter,
            idealProfit: firstResult.idealProfit + secondResult.idealProfit,
            profitPaid: firstResult.profitPaid + secondResult.profitPaid,
            insuranceBet: firstResult.insuranceBet,
            insuranceNetChange: firstResult.insuranceNetChange,
            insuranceProfitPaid: firstResult.insuranceProfitPaid
        )
        balance = combined.balanceAfter
        dealerBank = combined.dealerBankAfter
        activeBet = 0
        splitSecondBet = 0
        activeInsurance = 0
        lastSettlement = combined
        persist()
        return combined
    }

    func refundActiveBet() {
        guard activeBet > 0 || activeInsurance > 0 || splitSecondBet > 0 else { return }
        balance += activeBet + activeInsurance + splitSecondBet
        activeBet = 0
        splitSecondBet = 0
        activeInsurance = 0
        activeBetWasAllIn = false
        lastSettlement = nil
        persist()
    }

    func resetSession() {
        balance = sessionStartingBalance
        dealerBank = sessionDealerStartingBank
        activeBet = 0
        activeInsurance = 0
        splitSecondBet = 0
        activeBetWasAllIn = false
        lastSettlement = nil
        sessionRoundsCompleted = 0
        // 清除持久化，便于下次按新关卡起始筹码建会话；杀进程中途恢复仍依赖未 clear 的键。
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: dealerBankKey)
        defaults.removeObject(forKey: activeBetKey)
        defaults.removeObject(forKey: activeInsuranceKey)
        defaults.removeObject(forKey: splitSecondBetKey)
        defaults.removeObject(forKey: sessionRoundsKey)
    }

    /// 两手一胜一负记为平；分牌后不出现 3:2 天然黑杰克。
    static func combinedSplitOutcome(_ first: RoundOutcome, _ second: RoundOutcome) -> RoundOutcome {
        func score(_ outcome: RoundOutcome) -> Int {
            switch outcome {
            case .playerBlackjack, .playerWin:
                return 1
            case .push:
                return 0
            case .playerLose, .playerSurrender:
                return -1
            }
        }
        if first == second {
            return first == .playerBlackjack ? .playerWin : first
        }
        let total = score(first) + score(second)
        if total > 0 { return .playerWin }
        if total < 0 { return .playerLose }
        return .push
    }

    func abandonSession() {
        resetSession()
    }

    private func persist() {
        defaults.set(balance, forKey: storageKey)
        defaults.set(dealerBank, forKey: dealerBankKey)
        defaults.set(activeBet, forKey: activeBetKey)
        defaults.set(activeInsurance, forKey: activeInsuranceKey)
        defaults.set(splitSecondBet, forKey: splitSecondBetKey)
        defaults.set(sessionRoundsCompleted, forKey: sessionRoundsKey)
    }
}
