//
//  TableHUDTests.swift
//  cardsTests
//
//  牌桌顶栏目标 + 状态条阶段文案。
//

import Testing
@testable import cards

struct TableHUDTests {

    @Test func goalLineUsesStageTitleAndRemainingBank() {
        #expect(L10n.t("table.goal.remainingFormat", language: "zh-Hans") == "%@ · 庄家还剩 %d")
        #expect(L10n.t("table.goal.remainingFormat", language: "en") == "%@ · dealer has %d left")

        let challengeTitle = ChallengeRules.stage(level: 2).title
        #expect(
            TableHUD.goalLine(playStyle: .challenge, level: 2, dealerRemaining: 1400)
                == L10n.format("table.goal.remainingFormat", challengeTitle, 1400)
        )
        #expect(
            String(format: L10n.t("table.goal.remainingFormat", language: "zh-Hans"), "第二关", 1400)
                == "第二关 · 庄家还剩 1400"
        )
        #expect(
            String(
                format: L10n.t("table.goal.remainingFormat", language: "en"),
                "Stage 2",
                1400
            ) == "Stage 2 · dealer has 1400 left"
        )

        let entertainmentTitle = EntertainmentRules.stage(level: 1).title
        #expect(
            TableHUD.goalLine(playStyle: .entertainment, level: 1, dealerRemaining: 2000)
                == L10n.format("table.goal.remainingFormat", entertainmentTitle, 2000)
        )
    }

    @Test @MainActor
    func phaseStatusLinesMatchCatalog() {
        #expect(L10n.t("table.status.yourTurn", language: "zh-Hans") == "轮到你出牌")
        #expect(L10n.t("table.status.yourTurn", language: "en") == "Your turn")
        #expect(L10n.t("table.status.dealerTurn", language: "zh-Hans") == "庄家出牌中")
        #expect(L10n.t("table.status.dealerTurn", language: "en") == "Dealer is playing")
        #expect(L10n.t("table.status.dealing", language: "zh-Hans") == "发牌中…")
        #expect(L10n.t("table.status.dealing", language: "en") == "Dealing…")
        #expect(L10n.t("table.status.insurance", language: "zh-Hans") == "选择是否买保险")
        #expect(L10n.t("table.status.pickBet", language: "zh-Hans") == "选择注码")

        #expect(TableHUD.phaseStatusLine(phase: .playerTurn) == L10n.t("table.status.yourTurn"))
        #expect(TableHUD.phaseStatusLine(phase: .dealerTurn) == L10n.t("table.status.dealerTurn"))
        #expect(TableHUD.phaseStatusLine(phase: .dealing) == L10n.t("table.status.dealing"))
        #expect(TableHUD.phaseStatusLine(phase: .insuranceOffer) == L10n.t("table.status.insurance"))
        #expect(TableHUD.phaseStatusLine(phase: .idle) == L10n.t("table.status.pickBet"))
        #expect(TableHUD.phaseStatusLine(phase: .finished) == L10n.t("table.roundOver"))
        #expect(TableHUD.phaseStatusLine(phase: .playerTurn) != L10n.t("table.waitingResult"))
    }

    @Test @MainActor
    func phaseStatusIconsAreNotHourglassOnPlayerTurn() {
        #expect(TableHUD.phaseStatusIcon(phase: .playerTurn) == "hand.tap.fill")
        #expect(TableHUD.phaseStatusIcon(phase: .dealerTurn) == "person.fill")
        #expect(TableHUD.phaseStatusIcon(phase: .finished) == "checkmark.circle")
    }
}
