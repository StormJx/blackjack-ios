//
//  FirstSessionGuideTests.swift
//  cardsTests
//
//  首局引导：各模式一句目标；看过标记分轨持久化。
//

import Foundation
import Testing
@testable import cards

struct FirstSessionGuideTests {

    @Test func goalLinesMatchCatalogInBothLanguages() {
        #expect(L10n.t("guide.first.challengeFormat", language: "zh-Hans") == "目标：打穿庄家 %d")
        #expect(L10n.t("guide.first.challengeFormat", language: "en") == "Goal: clear the dealer bank (%d)")
        #expect(L10n.t("guide.first.entertainmentFormat", language: "zh-Hans") == "本阶目标：打穿庄家 %d")
        #expect(L10n.t("guide.first.entertainmentFormat", language: "en") == "Stage goal: clear the dealer bank (%d)")
        #expect(L10n.t("guide.first.gotIt", language: "zh-Hans") == "知道了")
        #expect(L10n.t("guide.first.gotIt", language: "en") == "Got it")
    }

    @Test func goalLineFormatsDealerStart() {
        #expect(
            String(format: L10n.t("guide.first.challengeFormat", language: "zh-Hans"), 2000)
                == "目标：打穿庄家 2000"
        )
        #expect(
            String(format: L10n.t("guide.first.entertainmentFormat", language: "zh-Hans"), 5000)
                == "本阶目标：打穿庄家 5000"
        )
        #expect(
            String(format: L10n.t("guide.first.challengeFormat", language: "en"), 7000)
                == "Goal: clear the dealer bank (7000)"
        )
        #expect(
            String(format: L10n.t("guide.first.entertainmentFormat", language: "en"), 9000)
                == "Stage goal: clear the dealer bank (9000)"
        )
        #expect(
            FirstSessionGuide.goalLine(playStyle: .challenge, dealerStart: 2000)
                == L10n.format("guide.first.challengeFormat", 2000)
        )
        #expect(
            FirstSessionGuide.goalLine(playStyle: .entertainment, dealerStart: 5000)
                == L10n.format("guide.first.entertainmentFormat", 5000)
        )
    }

    @Test @MainActor
    func firstGuideFlagsPersistPerMode() {
        let suiteName = "cards.tests.firstGuide.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        #expect(settings.hasSeenFirstSessionGuide(for: .challenge) == false)
        #expect(settings.hasSeenFirstSessionGuide(for: .entertainment) == false)

        settings.markFirstSessionGuideSeen(for: .entertainment)
        settings.markFirstSessionGuideSeen(for: .entertainment)

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.hasSeenEntertainmentFirstGuide == true)
        #expect(reloaded.hasSeenChallengeFirstGuide == false)

        reloaded.markFirstSessionGuideSeen(for: .challenge)
        let both = AppSettings(defaults: defaults)
        #expect(both.hasSeenChallengeFirstGuide == true)
        #expect(both.hasSeenEntertainmentFirstGuide == true)
    }
}
