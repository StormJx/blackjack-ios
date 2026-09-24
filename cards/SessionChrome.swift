//
//  SessionChrome.swift
//  cards
//
//  欢迎页牌副/切牌一行，以及局末「距下一关」一行。
//

import Foundation

enum WelcomeChrome {
    /// 欢迎页一行：当前牌副；闯关切牌跟设置，娱乐固定真实切牌。
    static func setupLine(practiceMode: PracticeMode, challengeCut: CutCardMode) -> String {
        L10n.format("welcome.setupFormat", practiceMode.shortLabel, challengeCut.title)
    }
}

enum SessionProgress {
    /// 局末一行：距下一关还差的打穿次数或累计赢码；满级为通关文案。
    static func gapLine(
        playStyle: PlayStyle,
        level: Int,
        dealerClears: Int,
        chipsWon: Int
    ) -> String {
        switch playStyle {
        case .challenge:
            return ChallengeRules.progressHint(
                unlockedLevel: level,
                dealerClears: dealerClears,
                totalChipsWon: chipsWon
            )
        case .entertainment:
            return EntertainmentRules.progressHint(
                unlockedLevel: level,
                dealerClears: dealerClears,
                totalChipsWon: chipsWon
            )
        }
    }
}
