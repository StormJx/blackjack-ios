//
//  SessionCoordinator.swift
//  cards
//
//  A1：局末结算 / 成就记账 / 进度与外观同步（从 GameSessionView 抽出，可单测）。
//

import Foundation

/// 一局结束编排结果（供 UI 脉冲余额、娱乐会话统计、解锁卡片队列）。
struct RoundFinishResult: Equatable {
    var settlement: SettlementResult?
    var unlockNotices: [String]
    /// 是否成功结算主注（用于余额动效）。
    var shouldPulseBalance: Bool
    /// 已记入会话局数的结局（娱乐 `FastSessionStats` 用）；无 outcome 时为 nil。
    var recordedOutcome: RoundOutcome?
}

/// 对局会话编排：筹码结算、成就、闯关/娱乐进度、道具与卡背同步。
@MainActor
final class SessionCoordinator: ObservableObject {
    let playStyle: PlayStyle
    let chipBank: ChipBank
    let statsStore: StatsStore
    let propStore: PropStore
    let challengeProgress: ChallengeProgress
    let entertainmentProgress: EntertainmentProgress
    let cosmeticsStore: CosmeticsStore

    init(
        playStyle: PlayStyle,
        chipBank: ChipBank,
        statsStore: StatsStore,
        propStore: PropStore,
        challengeProgress: ChallengeProgress,
        entertainmentProgress: EntertainmentProgress,
        cosmeticsStore: CosmeticsStore
    ) {
        self.playStyle = playStyle
        self.chipBank = chipBank
        self.statsStore = statsStore
        self.propStore = propStore
        self.challengeProgress = challengeProgress
        self.entertainmentProgress = entertainmentProgress
        self.cosmeticsStore = cosmeticsStore
    }

    // MARK: - 进度同步（欢迎页 / 会话结束共用）

    /// 用战绩对齐闯关关卡与卡背解锁。
    @discardableResult
    func syncProgressAndCosmetics() -> (leveledUp: Bool, newlyUnlockedBacks: [CardBackStyle]) {
        Self.syncProgressAndCosmetics(
            statsStore: statsStore,
            challengeProgress: challengeProgress,
            cosmeticsStore: cosmeticsStore
        )
    }

    @discardableResult
    static func syncProgressAndCosmetics(
        statsStore: StatsStore,
        challengeProgress: ChallengeProgress,
        cosmeticsStore: CosmeticsStore
    ) -> (leveledUp: Bool, newlyUnlockedBacks: [CardBackStyle]) {
        let leveledUp = challengeProgress.syncFromStats(
            dealerClears: statsStore.dealerBankClearCount,
            totalChipsWon: statsStore.totalChipsWon
        )
        let newlyBacks = cosmeticsStore.syncFromProgress(
            unlockedLevel: challengeProgress.unlockedLevel,
            dealerClears: statsStore.dealerBankClearCount,
            totalChipsWon: statsStore.totalChipsWon
        )
        return (leveledUp, newlyBacks)
    }

    /// App 启动 / 欢迎页：进度、卡背、道具对齐成就。
    static func syncOnAppAppear(
        statsStore: StatsStore,
        propStore: PropStore,
        challengeProgress: ChallengeProgress,
        cosmeticsStore: CosmeticsStore
    ) {
        _ = syncProgressAndCosmetics(
            statsStore: statsStore,
            challengeProgress: challengeProgress,
            cosmeticsStore: cosmeticsStore
        )
        _ = propStore.syncFromAchievements(statsStore.unlockedIDs)
    }

    // MARK: - 结算

    /// 有结局则结算并记账；无结局则退回未完成主注/保险。
    @discardableResult
    func settleRound(outcome: RoundOutcome?, insuranceWon: Bool) -> SettlementResult? {
        if let outcome {
            guard let result = chipBank.settle(
                outcome: outcome,
                insuranceWon: insuranceWon
            ) else {
                return nil
            }
            switch playStyle {
            case .challenge:
                statsStore.recordChipSettlement(netChange: result.netChange)
                _ = syncProgressAndCosmetics()
            case .entertainment:
                entertainmentProgress.recordChipsWon(result.netChange)
            }
            return result
        }
        if chipBank.activeBet > 0 || chipBank.activeInsurance > 0 {
            chipBank.refundActiveBet()
        }
        return nil
    }

    // MARK: - 成就 / 打穿 / 解锁通知

    /// 局末成就与打穿进度；须在 `settleRound` 之后调用（依赖 `sessionEndReason`）。
    func recordRoundFinished(
        snapshot: RoundSnapshot?,
        sessionEndReason: SessionEndReason?
    ) -> [String] {
        if let snapshot {
            let newly = statsStore.recordRound(
                snapshot: snapshot,
                scope: playStyle.achievementScope
            )
            var notices = newly.map(\.title)
            if playStyle == .challenge, sessionEndReason == .dealerBroke {
                let beforePending = statsStore.pendingUnlockTitles
                statsStore.recordDealerBankCleared()
                let afterPending = statsStore.pendingUnlockTitles
                let extra = afterPending.dropFirst(beforePending.count)
                notices.append(contentsOf: extra)
                if challengeProgress.syncFromStats(
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                ) {
                    notices.append(
                        L10n.format(
                            "unlock.challengePrefixFormat",
                            challengeProgress.currentStage.title
                        )
                    )
                }
            }
            if playStyle == .entertainment, sessionEndReason == .dealerBroke {
                if entertainmentProgress.recordDealerCleared() {
                    notices.append(
                        L10n.format(
                            "unlock.entertainmentStageFormat",
                            entertainmentProgress.currentStage.title
                        )
                    )
                } else {
                    notices.append(L10n.t("unlock.entertainmentClear"))
                }
            }
            let newlyProps = propStore.syncFromAchievements(statsStore.unlockedIDs)
            let newlyBacks = cosmeticsStore.syncFromProgress(
                unlockedLevel: challengeProgress.unlockedLevel,
                dealerClears: statsStore.dealerBankClearCount,
                totalChipsWon: statsStore.totalChipsWon
            )
            if playStyle == .entertainment {
                notices.append(
                    contentsOf: newlyProps.map { L10n.format("unlock.propFormat", $0.title) }
                )
            } else if !newlyProps.isEmpty {
                notices.append(L10n.t("unlock.propsUnlockedChallengeNote"))
            }
            notices.append(
                contentsOf: newlyBacks.map { L10n.format("unlock.cardBackFormat", $0.title) }
            )
            return notices
        }

        if playStyle == .challenge, sessionEndReason == .dealerBroke {
            statsStore.recordDealerBankCleared()
            _ = propStore.syncFromAchievements(statsStore.unlockedIDs)
            var notices: [String] = []
            if challengeProgress.syncFromStats(
                dealerClears: statsStore.dealerBankClearCount,
                totalChipsWon: statsStore.totalChipsWon
            ) {
                notices = [
                    L10n.format(
                        "unlock.challengePrefixFormat",
                        challengeProgress.currentStage.title
                    ),
                ]
            }
            _ = cosmeticsStore.syncFromProgress(
                unlockedLevel: challengeProgress.unlockedLevel,
                dealerClears: statsStore.dealerBankClearCount,
                totalChipsWon: statsStore.totalChipsWon
            )
            return notices
        }

        if playStyle == .entertainment, sessionEndReason == .dealerBroke {
            if entertainmentProgress.recordDealerCleared() {
                return [
                    L10n.format(
                        "unlock.entertainmentStageFormat",
                        entertainmentProgress.currentStage.title
                    ),
                ]
            }
            return []
        }

        return []
    }

    // MARK: - 局末入口（对应原 handleRoundFinished 业务部分）

    /// 结算 → 记局 → 成就/打穿/解锁；UI 侧再处理脉冲与娱乐会话统计。
    func finishRound(
        outcome: RoundOutcome?,
        insuranceWon: Bool,
        makeSnapshot: (_ wasAllInBet: Bool) -> RoundSnapshot?
    ) -> RoundFinishResult {
        let settlement = settleRound(outcome: outcome, insuranceWon: insuranceWon)
        guard let outcome else {
            return RoundFinishResult(
                settlement: nil,
                unlockNotices: [],
                shouldPulseBalance: false,
                recordedOutcome: nil
            )
        }

        chipBank.recordRoundCompleted()
        let snapshot = makeSnapshot(chipBank.activeBetWasAllIn)
        let notices = recordRoundFinished(
            snapshot: snapshot,
            sessionEndReason: chipBank.sessionEndReason
        )
        return RoundFinishResult(
            settlement: settlement,
            unlockNotices: notices,
            shouldPulseBalance: settlement != nil,
            recordedOutcome: outcome
        )
    }
}
