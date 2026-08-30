//
//  BasicStrategyTests.swift
//  cardsTests
//
//  T1：多副 S17 基础策略全表抽样。期望与 Wizard of Odds 4–8 副文本策略一致。
//

import Testing
@testable import cards

struct BasicStrategyTests {

    private let dealerRanks: [Rank] = [
        .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace,
    ]

    private func advise(
        _ hand: StrategyHand,
        vs dealer: Rank,
        double: Bool = true,
        surrender: Bool = true,
        split: Bool = true
    ) -> StrategyAction {
        BasicStrategy.advise(
            hand: hand,
            dealerUp: dealer,
            canDouble: double,
            canSurrender: surrender,
            canSplit: split
        )
    }

    // MARK: - 硬点 8–17 × 庄 2–A

    @Test func hardTotalsEightThroughSeventeenMatchS17Chart() {
        for dealer in dealerRanks {
            #expect(advise(.hard(8), vs: dealer) == .hit)

            let nine = advise(.hard(9), vs: dealer)
            if isDealer(dealer, in: .three, .four, .five, .six) {
                #expect(nine == .double)
            } else {
                #expect(nine == .hit)
            }

            let ten = advise(.hard(10), vs: dealer)
            if isDealer(dealer, in: .ten, .ace) {
                #expect(ten == .hit)
            } else {
                #expect(ten == .double)
            }

            let eleven = advise(.hard(11), vs: dealer)
            #expect(eleven == (dealer == .ace ? .hit : .double))

            let twelve = advise(.hard(12), vs: dealer)
            if isDealer(dealer, in: .four, .five, .six) {
                #expect(twelve == .stand)
            } else {
                #expect(twelve == .hit)
            }

            for total in 13...14 {
                let action = advise(.hard(total), vs: dealer)
                if isDealer(dealer, in: .two, .three, .four, .five, .six) {
                    #expect(action == .stand)
                } else {
                    #expect(action == .hit)
                }
            }

            let fifteen = advise(.hard(15), vs: dealer)
            if dealer == .ten {
                #expect(fifteen == .surrender)
            } else if isDealer(dealer, in: .two, .three, .four, .five, .six) {
                #expect(fifteen == .stand)
            } else {
                #expect(fifteen == .hit)
            }

            let sixteen = advise(.hard(16), vs: dealer)
            if isDealer(dealer, in: .nine, .ten, .ace) {
                #expect(sixteen == .surrender)
            } else if isDealer(dealer, in: .two, .three, .four, .five, .six) {
                #expect(sixteen == .stand)
            } else {
                #expect(sixteen == .hit)
            }

            #expect(advise(.hard(17), vs: dealer) == .stand)
        }
    }

    // MARK: - 软点 13–20

    @Test func softTotalsThirteenThroughTwentyMatchS17Chart() {
        for dealer in dealerRanks {
            #expect(softExpected(13, vs: dealer) == advise(.soft(13), vs: dealer))
            #expect(softExpected(14, vs: dealer) == advise(.soft(14), vs: dealer))
            #expect(softExpected(15, vs: dealer) == advise(.soft(15), vs: dealer))
            #expect(softExpected(16, vs: dealer) == advise(.soft(16), vs: dealer))
            #expect(softExpected(17, vs: dealer) == advise(.soft(17), vs: dealer))
            #expect(softExpected(18, vs: dealer) == advise(.soft(18), vs: dealer))
            #expect(advise(.soft(19), vs: dealer) == .stand)
            #expect(advise(.soft(20), vs: dealer) == .stand)
        }
    }

    // MARK: - 对子全行

    @Test func pairTableAllRowsMatchS17DAS() {
        for dealer in dealerRanks {
            #expect(advise(.pair(.two), vs: dealer) == pair22or33(vs: dealer))
            #expect(advise(.pair(.three), vs: dealer) == pair22or33(vs: dealer))
            #expect(advise(.pair(.four), vs: dealer) == pair44(vs: dealer))
            #expect(advise(.pair(.five), vs: dealer) == pair55(vs: dealer))
            #expect(advise(.pair(.six), vs: dealer) == pair66(vs: dealer))
            #expect(advise(.pair(.seven), vs: dealer) == pair77(vs: dealer))
            #expect(advise(.pair(.eight), vs: dealer) == .split)
            #expect(advise(.pair(.nine), vs: dealer) == pair99(vs: dealer))
            #expect(advise(.pair(.ten), vs: dealer) == .stand)
            #expect(advise(.pair(.ace), vs: dealer) == .split)
        }
    }

    /// S17：8,8 对 A 仍分；H17 才会投降。硬 16（非对 8）对 A 才投降。
    @Test func pairOfEightsVersusAceSplitsInS17() {
        #expect(advise(.pair(.eight), vs: .ace) == .split)
        #expect(advise(.hard(16), vs: .ace) == .surrender)
    }

    /// S17：11 对 A 要牌；H17 才加倍。
    @Test func hardElevenVersusAceHitsInS17() {
        #expect(advise(.hard(11), vs: .ace) == .hit)
        #expect(advise(.hard(11), vs: .ten) == .double)
    }

    // MARK: - 投降格与回退

    @Test func surrenderCellsAndFallbacks() {
        #expect(advise(.hard(15), vs: .ten) == .surrender)
        #expect(advise(.hard(15), vs: .nine) == .hit)
        #expect(advise(.hard(15), vs: .ace) == .hit)
        #expect(advise(.hard(16), vs: .nine) == .surrender)
        #expect(advise(.hard(16), vs: .ten) == .surrender)
        #expect(advise(.hard(16), vs: .ace) == .surrender)
        #expect(advise(.hard(17), vs: .ace) == .stand)

        #expect(advise(.hard(16), vs: .ten, surrender: false) == .hit)
        #expect(advise(.hard(15), vs: .ten, surrender: false) == .hit)
        #expect(advise(.hard(16), vs: .ace, surrender: false) == .hit)
    }

    @Test func doubleFallbackHitsOrStands() {
        #expect(advise(.hard(11), vs: .six, double: false) == .hit)
        #expect(advise(.hard(10), vs: .five, double: false) == .hit)
        #expect(advise(.hard(9), vs: .four, double: false) == .hit)
        #expect(advise(.soft(18), vs: .four, double: false) == .stand)
        #expect(advise(.soft(17), vs: .three, double: false) == .hit)
        #expect(advise(.soft(13), vs: .six, double: false) == .hit)
    }

    @Test func cannotSplitFallsBackToHardOrSoft() {
        #expect(advise(.pair(.eight), vs: .ten, split: false) == .surrender)
        #expect(advise(.pair(.eight), vs: .six, split: false) == .stand)
        #expect(advise(.pair(.eight), vs: .seven, split: false) == .hit)
        #expect(advise(.pair(.ace), vs: .six, split: false) == .hit)
        #expect(advise(.pair(.two), vs: .four, split: false) == .hit)
        #expect(advise(.pair(.nine), vs: .seven, split: false) == .stand)
        #expect(advise(.pair(.five), vs: .six, split: false) == .double)
    }

    // MARK: - 从牌面分类

    @Test func classifyPairSoftAndHardFromCards() {
        #expect(BasicStrategy.classify([card(.eight), card(.eight)]) == .pair(.eight))
        #expect(BasicStrategy.classify([card(.jack), card(.queen)]) == .pair(.ten))
        #expect(BasicStrategy.classify([card(.ace), card(.ace)]) == .pair(.ace))
        #expect(BasicStrategy.classify([card(.ace), card(.six)]) == .soft(17))
        #expect(BasicStrategy.classify([card(.ten), card(.seven)]) == .hard(17))
        #expect(BasicStrategy.classify([card(.ace), card(.ten)]) == .soft(21))
        #expect(BasicStrategy.classify([card(.ten), card(.six), card(.two)]) == .hard(18))
        #expect(BasicStrategy.classify([card(.ace), card(.two), card(.three)]) == .soft(16))
    }

    @Test func adviseFromCardsUsesClassification() {
        let eightsVsTen = BasicStrategy.advise(
            playerCards: [card(.eight), card(.eight)],
            dealerUp: .ten,
            canDouble: true,
            canSurrender: true,
            canSplit: true
        )
        #expect(eightsVsTen == .split)

        let hardSixteenVsTen = BasicStrategy.advise(
            playerCards: [card(.ten), card(.six)],
            dealerUp: .king,
            canDouble: true,
            canSurrender: true,
            canSplit: false
        )
        #expect(hardSixteenVsTen == .surrender)

        let softEighteenVsNine = BasicStrategy.advise(
            playerCards: [card(.ace), card(.seven)],
            dealerUp: .nine,
            canDouble: true,
            canSurrender: true,
            canSplit: false
        )
        #expect(softEighteenVsNine == .hit)
    }

    // MARK: - 期望推导

    private func softExpected(_ total: Int, vs dealer: Rank) -> StrategyAction {
        switch total {
        case 13, 14:
            return isDealer(dealer, in: .five, .six) ? .double : .hit
        case 15, 16:
            return isDealer(dealer, in: .four, .five, .six) ? .double : .hit
        case 17:
            return isDealer(dealer, in: .three, .four, .five, .six) ? .double : .hit
        case 18:
            if isDealer(dealer, in: .three, .four, .five, .six) { return .double }
            if isDealer(dealer, in: .nine, .ten, .ace) { return .hit }
            return .stand
        default:
            return .stand
        }
    }

    private func pair22or33(vs dealer: Rank) -> StrategyAction {
        isDealer(dealer, in: .two, .three, .four, .five, .six, .seven) ? .split : .hit
    }

    private func pair44(vs dealer: Rank) -> StrategyAction {
        isDealer(dealer, in: .five, .six) ? .split : .hit
    }

    private func pair55(vs dealer: Rank) -> StrategyAction {
        isDealer(dealer, in: .ten, .ace) ? .hit : .double
    }

    private func pair66(vs dealer: Rank) -> StrategyAction {
        isDealer(dealer, in: .two, .three, .four, .five, .six) ? .split : .hit
    }

    private func pair77(vs dealer: Rank) -> StrategyAction {
        isDealer(dealer, in: .two, .three, .four, .five, .six, .seven) ? .split : .hit
    }

    private func pair99(vs dealer: Rank) -> StrategyAction {
        if isDealer(dealer, in: .seven, .ten, .ace) { return .stand }
        return .split
    }

    private func isDealer(_ dealer: Rank, in ranks: Rank...) -> Bool {
        let normalized = (dealer == .jack || dealer == .queen || dealer == .king) ? Rank.ten : dealer
        return ranks.contains(normalized)
    }

    private func card(_ rank: Rank) -> Card {
        Card(suit: .spades, rank: rank)
    }
}
