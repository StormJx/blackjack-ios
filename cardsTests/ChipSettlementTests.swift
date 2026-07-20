//
//  ChipSettlementTests.swift
//  cardsTests
//
//  阶段 3 / 3.5：筹码结算、庄家资金池与会话结束单元测试。
//

import Testing
import Foundation
@testable import cards

struct ChipSettlementTests {

    // MARK: - 纯结算算术（庄家资金充足）

    @Test func blackjackPaysThreeToTwo() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .playerBlackjack
        )
        // 净盈 +150；退本 100 + 派彩 150 → 打回 250 → 余额 1150；庄家 2000−150
        #expect(result.netChange == 150)
        #expect(result.amountReturned == 250)
        #expect(result.balanceAfter == 1150)
        #expect(result.dealerBankAfter == 1850)
        #expect(result.profitPaid == 150)
        #expect(result.idealProfit == 150)
        #expect(result.wasPartialPayout == false)
        #expect(result.oddsLabel == ChipRules.blackjackOddsLabel)
        #expect(result.netChangeLabel == "+150")
    }

    @Test func evenMoneyPaysOneToOne() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .playerWin
        )
        #expect(result.netChange == 100)
        #expect(result.amountReturned == 200)
        #expect(result.balanceAfter == 1100)
        #expect(result.dealerBankAfter == 1900)
        #expect(result.oddsLabel == ChipRules.evenMoneyOddsLabel)
    }

    @Test func loseForfeitsStakeToDealerBank() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .playerLose
        )
        #expect(result.netChange == -100)
        #expect(result.amountReturned == 0)
        #expect(result.balanceAfter == 900)
        #expect(result.dealerBankAfter == 2100)
        #expect(result.oddsLabel == nil)
        #expect(result.netChangeLabel == "-100")
    }

    @Test func pushReturnsStakeWithDealerBankUnchanged() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .push
        )
        #expect(result.netChange == 0)
        #expect(result.amountReturned == 100)
        #expect(result.balanceAfter == 1000)
        #expect(result.dealerBankAfter == ChipRules.dealerStartingBank)
        #expect(result.netChangeLabel == "0（平局退注）")
        #expect(result.oddsLabel == nil)
    }

    @Test func blackjackProfitUsesIntegerDivision() {
        #expect(ChipRules.blackjackProfit(forBet: 25) == 37)
        let result = RoundSettlement.settle(
            balanceAfterBet: 975,
            betAmount: 25,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .playerBlackjack
        )
        #expect(result.netChange == 37)
        #expect(result.amountReturned == 62)
        #expect(result.balanceAfter == 1037)
        #expect(result.dealerBankAfter == ChipRules.dealerStartingBank - 37)
    }

    @Test(arguments: [10, 20, 50, 100, 200])
    func evenBetsBlackjackProfitIsExactHalfSteps(bet: Int) {
        let profit = ChipRules.blackjackProfit(forBet: bet)
        #expect(profit == (bet * 3) / 2)
        let before = 1000 - bet
        let result = RoundSettlement.settle(
            balanceAfterBet: before,
            betAmount: bet,
            dealerBank: ChipRules.dealerStartingBank,
            outcome: .playerBlackjack
        )
        #expect(result.balanceAfter == before + bet + profit)
        #expect(result.balanceAfter == 1000 + profit)
        #expect(result.dealerBankAfter == ChipRules.dealerStartingBank - profit)
    }

    // MARK: - 不足额赔付（有多少赔多少）

    @Test func partialPayoutWhenDealerCannotCoverFullProfit() {
        // 应付 150，庄家仅剩 40 → 只赔 40，本金仍退回。
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: 40,
            outcome: .playerBlackjack
        )
        #expect(result.idealProfit == 150)
        #expect(result.profitPaid == 40)
        #expect(result.netChange == 40)
        #expect(result.amountReturned == 140)
        #expect(result.balanceAfter == 1040)
        #expect(result.dealerBankAfter == 0)
        #expect(result.wasPartialPayout)
        #expect(result.partialPayoutLabel == ChipRules.partialPayoutLabel)
    }

    @Test func partialPayoutEvenMoneyEmptiesDealerBank() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 800,
            betAmount: 200,
            dealerBank: 50,
            outcome: .playerWin
        )
        #expect(result.idealProfit == 200)
        #expect(result.profitPaid == 50)
        #expect(result.netChange == 50)
        #expect(result.amountReturned == 250)
        #expect(result.balanceAfter == 1050)
        #expect(result.dealerBankAfter == 0)
        #expect(result.wasPartialPayout)
    }

    @Test func zeroDealerBankOnWinReturnsStakeOnly() {
        let result = RoundSettlement.settle(
            balanceAfterBet: 900,
            betAmount: 100,
            dealerBank: 0,
            outcome: .playerWin
        )
        #expect(result.profitPaid == 0)
        #expect(result.netChange == 0)
        #expect(result.amountReturned == 100)
        #expect(result.balanceAfter == 1000)
        #expect(result.dealerBankAfter == 0)
        #expect(result.wasPartialPayout)
    }

    // MARK: - 三档单选 / 全下解锁

    @Test func canSelectBetChipIsSingleTierOnly() {
        #expect(ChipRules.canSelectBetChip(100, balance: 1000))
        #expect(ChipRules.canSelectBetChip(200, balance: 1000))
        #expect(ChipRules.canSelectBetChip(500, balance: 1000))
        #expect(ChipRules.canSelectBetChip(300, balance: 1000) == false)
        #expect(ChipRules.canSelectBetChip(200, balance: 150) == false)
        #expect(ChipRules.canSelectBetChip(100, balance: 150))
    }

    @Test func preDealAllInRequiresUnlockAndNoChipSelection() {
        #expect(ChipRules.canPreDealAllIn(balance: ChipRules.minimumBet))
        #expect(ChipRules.canPreDealAllIn(balance: ChipRules.minimumBet - 1) == false)

        // 未满 5 局：不可全下
        #expect(ChipRules.isPreDealAllInEnabled(
            balance: 1000,
            sessionRoundsCompleted: 4,
            draftBet: 0
        ) == false)
        #expect(ChipRules.preDealAllInLockHint(sessionRoundsCompleted: 4) == "再玩 1 局后解锁全下")

        // 满 5 局且未选档：可全下
        #expect(ChipRules.isPreDealAllInEnabled(
            balance: 1000,
            sessionRoundsCompleted: 5,
            draftBet: 0
        ))
        #expect(ChipRules.preDealAllInLockHint(sessionRoundsCompleted: 5) == nil)

        // 已选筹码档：全下灰显
        #expect(ChipRules.isPreDealAllInEnabled(
            balance: 1000,
            sessionRoundsCompleted: 5,
            draftBet: 200
        ) == false)
        #expect(ChipRules.midHandAllInEnabled == false)
    }

    // MARK: - 开局全下 / 对局中全下（道具预留 API）

    @Test func canPreDealAllInRequiresMinimumBalance() {
        #expect(ChipRules.canPreDealAllIn(balance: ChipRules.minimumBet))
        #expect(ChipRules.canPreDealAllIn(balance: ChipRules.startingBalance))
        #expect(ChipRules.canPreDealAllIn(balance: ChipRules.minimumBet - 1) == false)
        #expect(ChipRules.midHandAllInEnabled == false)
    }

    @MainActor
    @Test func placeBetMarksAllInWhenEntireBalance() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        let stake = bank.balance
        #expect(ChipRules.canPreDealAllIn(balance: stake))
        #expect(bank.placeBet(stake))
        #expect(bank.balance == 0)
        #expect(bank.activeBet == stake)
        #expect(bank.activeBetWasAllIn)
    }

    @MainActor
    @Test func placeBetDoesNotMarkAllInForPartialStake() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        #expect(bank.activeBetWasAllIn == false)
    }

    @MainActor
    @Test func midHandGoAllInAddsRemainingBalanceToActiveBet() {
        // 道具预留 API：默认 UI 关闭，结算层仍保留见牌后追加。
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        #expect(bank.balance == 900)
        #expect(bank.activeBet == 100)
        #expect(bank.goAllIn() == 900)
        #expect(bank.balance == 0)
        #expect(bank.activeBet == 1000)
        #expect(bank.goAllIn() == nil)
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
    @Test func freshInstallStartsWithPlayerAndDealerBanks() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.isSessionOver == false)
        #expect(bank.activeBet == 0)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == ChipRules.startingBalance)
        #expect(defaults.integer(forKey: ChipRules.dealerBankStorageKey) == ChipRules.dealerStartingBank)
    }

    @MainActor
    @Test func placeBetDeductsBalanceOnce() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        #expect(bank.balance == 900)
        #expect(bank.activeBet == 100)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.placeBet(50) == false)
        #expect(bank.balance == 900)
    }

    @MainActor
    @Test func settleBlackjackUpdatesBothBanks() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        let result = bank.settle(outcome: .playerBlackjack)
        #expect(result?.netChange == 150)
        #expect(bank.balance == 1150)
        #expect(bank.dealerBank == 1850)
        #expect(bank.activeBet == 0)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == 1150)
        #expect(defaults.integer(forKey: ChipRules.dealerBankStorageKey) == 1850)

        #expect(bank.settle(outcome: .playerWin) == nil)
        #expect(bank.balance == 1150)
    }

    @MainActor
    @Test func settleLoseAndPushMatchUILabels() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)

        #expect(bank.placeBet(100))
        let lose = bank.settle(outcome: .playerLose)
        #expect(lose?.netChangeLabel == "-100")
        #expect(bank.balance == 900)
        #expect(bank.dealerBank == 2100)

        #expect(bank.placeBet(100))
        let push = bank.settle(outcome: .push)
        #expect(push?.netChangeLabel == "0（平局退注）")
        #expect(bank.balance == 900)
        #expect(bank.dealerBank == 2100)
    }

    @MainActor
    @Test func settlePartialPayoutEndsDealerSession() {
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(1000, forKey: ChipRules.balanceStorageKey)
        defaults.set(40, forKey: ChipRules.dealerBankStorageKey)
        defaults.set(0, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        let result = bank.settle(outcome: .playerBlackjack)
        #expect(result?.wasPartialPayout == true)
        #expect(bank.dealerBank == 0)
        #expect(bank.sessionEndReason == .dealerBroke)
        #expect(bank.isSessionOver)
        #expect(bank.placeBet(ChipRules.minimumBet) == false)
    }

    @MainActor
    @Test func playerBrokeEndsSession() {
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(5, forKey: ChipRules.balanceStorageKey)
        defaults.set(ChipRules.dealerStartingBank, forKey: ChipRules.dealerBankStorageKey)
        defaults.set(0, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.sessionEndReason == .playerBroke)
        #expect(bank.isSessionOver)
        #expect(bank.placeBet(ChipRules.minimumBet) == false)
    }

    @MainActor
    @Test func resetSessionRestoresBothStartingBanks() {
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(5, forKey: ChipRules.balanceStorageKey)
        defaults.set(0, forKey: ChipRules.dealerBankStorageKey)
        defaults.set(0, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.isSessionOver)
        bank.resetSession()
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.isSessionOver == false)
        #expect(bank.lastSettlement == nil)
    }

    @MainActor
    @Test func abandonSessionClearsProgressLikeReset() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        _ = bank.settle(outcome: .playerWin)
        #expect(bank.balance == 1100)
        bank.abandonSession()
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(defaults.integer(forKey: ChipRules.balanceStorageKey) == ChipRules.startingBalance)
    }

    @MainActor
    @Test func orphanActiveBetIsRefundedOnLaunch() {
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(0, forKey: ChipRules.balanceStorageKey)
        defaults.set(ChipRules.dealerStartingBank, forKey: ChipRules.dealerBankStorageKey)
        defaults.set(1000, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == 1000)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.activeBet == 0)
        #expect(bank.isSessionOver == false)
        #expect(defaults.integer(forKey: ChipRules.activeBetStorageKey) == 0)
        // C9：杀进程恢复应打标，供 UI 提示（与主动退出清空相对）。
        #expect(bank.didRestoreAfterInterrupt)
        bank.acknowledgeRestoreHint()
        #expect(bank.didRestoreAfterInterrupt == false)
    }

    @MainActor
    @Test func placeBetAcceptsAllInOddBalance() {
        // UI 仅三档单选；全下仍可通过 placeBet(全部余额) 下非整档注码。
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(150, forKey: ChipRules.balanceStorageKey)
        defaults.set(ChipRules.dealerStartingBank, forKey: ChipRules.dealerBankStorageKey)
        defaults.set(0, forKey: ChipRules.activeBetStorageKey)
        let bank = ChipBank(defaults: defaults)
        #expect(ChipRules.canSelectBetChip(100, balance: 150))
        #expect(ChipRules.canSelectBetChip(200, balance: 150) == false)
        #expect(bank.placeBet(150))
        #expect(bank.balance == 0)
        #expect(bank.activeBet == 150)
    }

    @MainActor
    @Test func legacyLowBalanceWithoutDealerKeyIsRepaired() {
        let defaults = Self.makeEphemeralDefaults()
        defaults.set(0, forKey: ChipRules.balanceStorageKey)
        #expect(defaults.object(forKey: ChipRules.activeBetStorageKey) == nil)
        #expect(defaults.object(forKey: ChipRules.dealerBankStorageKey) == nil)
        let bank = ChipBank(defaults: defaults)
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.isSessionOver == false)
    }

    @MainActor
    @Test func refundActiveBetRestoresBalanceWithoutSettlement() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(100))
        bank.refundActiveBet()
        #expect(bank.balance == ChipRules.startingBalance)
        #expect(bank.dealerBank == ChipRules.dealerStartingBank)
        #expect(bank.activeBet == 0)
        #expect(bank.lastSettlement == nil)
    }

    @MainActor
    @Test func rejectedBetsBelowMinimumOrAboveBalance() {
        let defaults = Self.makeEphemeralDefaults()
        let bank = ChipBank(defaults: defaults)
        #expect(bank.placeBet(ChipRules.minimumBet - 1) == false)
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
