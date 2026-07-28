//
//  SessionConfiguration.swift
//  cards
//
//  Q2：会话级桌限与开局全下解锁局数（新开局时锁定，对局中改设置不生效）。
//

import Foundation

/// 一次对局会话的不可变桌面配置。
struct SessionConfiguration: Equatable, Sendable {
    let minimumBet: Int
    let betChipValues: [Int]
    let preDealAllInUnlockRounds: Int

    static func challenge(
        preset: TableLimitPreset,
        unlockRounds: Int
    ) -> SessionConfiguration {
        SessionConfiguration(
            minimumBet: preset.minimumBet,
            betChipValues: preset.betChipValues,
            preDealAllInUnlockRounds: ChipRules.clampPreDealAllInUnlockRounds(unlockRounds)
        )
    }

    static func entertainment(
        stage: EntertainmentStage,
        unlockRounds: Int
    ) -> SessionConfiguration {
        SessionConfiguration(
            minimumBet: stage.minimumBet,
            betChipValues: stage.betChipValues,
            preDealAllInUnlockRounds: ChipRules.clampPreDealAllInUnlockRounds(unlockRounds)
        )
    }

    /// 同步到进程内 Active*（逐步替代散落的 apply 调用）。
    func applyToProcessGlobals() {
        ActiveTableLimits.apply(minimumBet: minimumBet, betChipValues: betChipValues)
        ActivePreDealAllInUnlock.apply(preDealAllInUnlockRounds)
    }
}
