//
//  ChipSettlementTests.swift
//  cardsTests
//
//  阶段 3（v1.7）：筹码结算与账户单元测试。
//

import Testing
import Foundation
@testable import cards

struct ChipSettlementTests {

    // MARK: - 纯结算算术

    @Test func blackjackPaysThreeToTwo() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            outcome: .playerBlackjack
        )
        // 净盈 +150（相对开局前 1000）；退本 100 + 派彩 150 → 打回 250 → 余额 1150
        #expect(result.netChange == 150)
        #expect(result.amountReturned == 250)
        #expect(result.balanceAfter == 1150)
        #expect(result.oddsLabel == ChipRules.blackjackOddsLabel)
        #expect(result.netChangeLabel == "+150")
    }

    @Test func evenMoneyPaysOneToOne() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            outcome: .playerWin
        )
        #expect(result.netChange == 100)
        #expect(result.amountReturned == 200)
        #expect(result.balanceAfter == 1100)
        #expect(result.oddsLabel == ChipRules.evenMoneyOddsLabel)
    }

    @Test func loseForfeitsStake() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            outcome: .playerLose
        )
        #expect(result.netChange == -100)
        #expect(result.amountReturned == 0)
        #expect(result.balanceAfter == 900)
        #expect(result.oddsLabel == nil)
        #expect(result.netChangeLabel == "-100")
    }

    @Test func pushReturnsStakeWithZeroNet() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            outcome: .push
        )
        #expect(result.netChange == 0)
        #expect(result.amountReturned == 100)
        #expect(result.balanceAfter == 1000)
        #expect(result.netChangeLabel == "0（平局退注）")
        #expect(result.oddsLabel == nil)
    }

    @Test func blackjackProfitUsesIntegerDivision() {
        // 25 × 3 / 2 = 37（向下取整）
        #expect(ChipRules.blackjackProfit(forBet: 25) == 37)
        let result = RoundSettlement.settle(
            balanceAfterBet: 975,
            betAmount: 25,
            outcome: .playerBlackjack
        )
        #expect(result.netChange == 37)
        #expect(result.amountReturned == 62)
        #expect(result.balanceAfter == 1037)
    }

    @Test(arguments: [10, 20, 50, 100, 200])
    func evenBetsBlackjackProfitIsExactHalfSteps(bet: Int) {
        let profit = ChipRules.blackjackProfit(forBet: bet)
        #expect(profit == (bet * 3) / 2)
        let before = 1000 - bet
        let result = RoundSettlement.settle(
            balanceAfterBet: before,
            betAmount: bet,
            outcome: .playerBlackjack
        )
        #expect(result.balanceAfter == before + bet + profit)
        #expect(result.balanceAfter == 1000 + profit)
    }

    // MARK: - All In 门槛与强制 All In

    @Test func standardAllInRequiresBalanceAboveStarting() {
        #expect(ChipRules.canUseStandardAllIn(balance: ChipRules.startingBalance) == false)
        #expect(ChipRules.canUseStandardAllIn(balance: ChipRules.startingBalance + 1))
        #expect(ChipRules.canUseStandardAllIn(balance: ChipRules.minimumBet) == false)
    }

    @Test func forcedAllInOnSingleDeckWhenRemainingAtMostThresholdAndNoReshuffle() {
        #expect(
            ChipRules.canUseForcedAllIn(
                isSingleDeck: true,
                remainingCards: ChipRules.forcedAllInRemainingCards,
                willReshuffle: false
            )
        )
        #expect(
            ChipRules.canUseForcedAllIn(
                isSingleDeck: true,
                remainingCards: ChipRules.forcedAllInRemainingCards - 1,
                willReshuffle: false
            )
        )
        #expect(
            ChipRules.canUseForcedAllIn(
                isSingleDeck: true,
                remainingCards: ChipRules.forcedAllInRemainingCards + 1,
                willReshuffle: false
            ) == false
        )
        #expect(
            ChipRules.canUseForcedAllIn(
                isSingleDeck: true,
                remainingCards: ChipRules.forcedAllInRemainingCards,
                willReshuffle: true
            ) == false
        )
        #expect(
            ChipRules.canUseForcedAllIn(
                isSingleDeck: false,
                remainingCards: ChipRules.forcedAllInRemainingCards,
                willReshuffle: false
            ) == false
        )
    }

    // MARK: - ChipBank 协调层

    @MainActor
    @Test func placeBetDeductsBalanceOnce() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.placeBet(100))
        #expect(bank.balance == 900)
        #expect(bank.activeBet == 100)
        #expect(bank.placeBet(50) == false) // 不可重复下注
        #expect(bank.balance == 900)
    }

    @MainActor
    @Test func settleBlackjackUpdatesPersistedBalance() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        let result = bank.settle(outcome: .playerBlackjack)
        #expect(result?.netChange == 150)
        #expect(bank.balance == 1150)
        #expect(bank.activeBet == 0)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == 1150)

        // 同一局不可重复结算
        #expect(bank.settle(outcome: .playerWin) == nil)
        #expect(bank.balance == 1150)
    }

    @MainActor
    @Test func settleLoseAndPushMatchUILabels() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)

        #expect(bank.placeBet(50))
        let lose = bank.settle(outcome: .playerLose)
        #expect(lose?.netChangeLabel == "-50")
        #expect(bank.balance == 950)

        #expect(bank.placeBet(50))
        let push = bank.settle(outcome: .push)
        #expect(push?.netChangeLabel == "0（平局退注）")
        #expect(bank.balance == 950)
    }

    @MainActor
    @Test func refillRestoresStartingBalanceWhenBroke() {
        let defaults = Self.makeEphemeralDefaults()
        // 已写入 activeBet 键，表示非「旧版误扣款」；低余额视为真实破产。
        defaults.set(5, forKey: ChipRules.balanceStorageKey)
        defaults.set(0, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.needsRefill)
        #expect(bank.placeBet(ChipRules.minimumBet) == false)
        bank.refillToStartingBalance()
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.needsRefill == false)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == ChipRules.startingBalance)
    }

    @MainActor
    @Test func freshInstallStartsWithStartingBalance() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.needsRefill == false)
        #expect(bank.activeBet == 0)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == ChipRules.startingBalance)
    }

    @MainActor
    @Test func orphanActiveBetIsRefundedOnLaunch() {
        let defaults = Self.makeEphemeralDefaults()
        // 模拟：已扣注并存盘后进程中断，activeBet 未结算。
        defaults.set(0, forKey: ChipRules.balanceStorageKey)
        defaults.set(1000, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == 1000)
        #expect(bank.activeBet == 0)
        #expect(bank.needsRefill == false)
        #expect(defaults.integer(forKey: ChipRules.activeBetStorageKey) == 0)
    }

    @MainActor
    @Test func legacyLowBalanceWithoutActiveBetKeyIsRepaired() {
        let defaults = Self.makeEphemeralDefaults()
        // 旧版：扣光余额后返回，未写入 activeBet 键。
        defaults.set(0, forKey: ChipRules.balanceStorageKey)
        #expect(defaults.object(forKey: ChipRules.activeBetStorageKey) == nil)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.needsRefill == false)
    }

    @MainActor
    @Test func refundActiveBetRestoresBalanceWithoutSettlement() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        bank.refundActiveBet()
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.activeBet == 0)
        #expect(bank.lastSettlement == nil)
    }

    @MainActor
    @Test func rejectedBetsBelowMinimumOrAboveBalance() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(5) == false)
        #expect(bank.placeBet(ChipRules.startingBalance + 1) == false)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.activeBet == 0)
    }

    // MARK: - Helpers

    private static func makeEphemeralDefaults() -> UserDefaults {
        let suite = "cards.tests.chip.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
