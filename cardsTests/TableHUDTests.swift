//
//  TableHUDTests.swift
//  cardsTests
//
//  牌桌顶栏目标 + 状态条阶段文案。
//

import Testing
@testable import cards

struct TableHUDTests {

    @Test func goalLineUsesStageTitleOnly() {
        #expect(TableHUD.goalLine(playStyle: .challenge, level: 2) == ChallengeRules.stage(level: 2).title)
        #expect(TableHUD.goalLine(playStyle: .entertainment, level: 1) == EntertainmentRules.stage(level: 1).title)
        #expect(TableHUD.goalLine(playStyle: .challenge, level: 2).contains("1400") == false)
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

struct SessionChromeTests {

    @Test func welcomeSetupLineNamesDeckAndCuts() {
        #expect(L10n.t("welcome.setupFormat", language: "zh-Hans") == "%@ · 闯关：%@ · 娱乐固定真实切牌")
        #expect(
            L10n.t("welcome.setupFormat", language: "en")
                == "%@ · Challenge: %@ · Entertainment stays on a real cut"
        )
        #expect(
            WelcomeChrome.setupLine(practiceMode: .singleDeck, challengeCut: .real)
                == L10n.format(
                    "welcome.setupFormat",
                    PracticeMode.singleDeck.shortLabel,
                    CutCardMode.real.title
                )
        )
        #expect(
            String(
                format: L10n.t("welcome.setupFormat", language: "zh-Hans"),
                "一副牌",
                "真实切牌"
            ) == "一副牌 · 闯关：真实切牌 · 娱乐固定真实切牌"
        )
    }

    @Test func gapLineMatchesProgressHint() {
        #expect(
            SessionProgress.gapLine(playStyle: .challenge, level: 1, dealerClears: 0, chipsWon: 200)
                == ChallengeRules.progressHint(unlockedLevel: 1, dealerClears: 0, totalChipsWon: 200)
        )
        #expect(
            SessionProgress.gapLine(playStyle: .entertainment, level: 2, dealerClears: 1, chipsWon: 100)
                == EntertainmentRules.progressHint(unlockedLevel: 2, dealerClears: 1, totalChipsWon: 100)
        )
    }
}
