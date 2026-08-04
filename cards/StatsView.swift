//
//  StatsView.swift
//  cards
//
//  战绩摘要：分模式胜负 + F2 关卡/阶梯进度（当前关与下一门槛）。
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: StatsStore
    @ObservedObject var challengeProgress: ChallengeProgress
    @ObservedObject var entertainmentProgress: EntertainmentProgress

    var body: some View {
        NavigationStack {
            List {
                challengeSection
                entertainmentSection
            }
            .navigationTitle(L10n.t("stats.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var challengeSection: some View {
        let stage = challengeProgress.currentStage
        let hint = ChallengeRules.progressHint(
            unlockedLevel: challengeProgress.unlockedLevel,
            dealerClears: stats.dealerBankClearCount,
            totalChipsWon: stats.totalChipsWon
        )
        return Section {
            Text(ChallengeRules.stageBankSummary(level: challengeProgress.unlockedLevel))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .accessibilityLabel(
                    L10n.format(
                        "stats.a11y.stageBankFormat",
                        stage.title,
                        stage.playerStart,
                        stage.dealerStart
                    )
                )

            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(hint)

            if stats.challenge.rounds > 0 {
                Text(stats.recordSummaryLine(for: .challenge))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(stats.chipsSummaryLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text(L10n.t("stats.empty.challenge"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } header: {
            Text(L10n.t("stats.section.challenge"))
        } footer: {
            Text(L10n.t("stats.footer.challenge"))
        }
    }

    private var entertainmentSection: some View {
        let stage = entertainmentProgress.currentStage
        let hint = EntertainmentRules.progressHint(
            unlockedLevel: entertainmentProgress.unlockedLevel,
            dealerClears: entertainmentProgress.dealerClearCount,
            totalChipsWon: entertainmentProgress.totalChipsWon
        )
        return Section {
            Text(EntertainmentRules.stageBankSummary(level: entertainmentProgress.unlockedLevel))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .accessibilityLabel(
                    L10n.format(
                        "stats.a11y.stageBankFormat",
                        stage.title,
                        stage.playerStart,
                        stage.dealerStart
                    )
                )

            Text(stage.tableLimitsSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(stage.tableLimitsSummary)

            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(hint)

            Text(entertainmentProgress.chipsSummaryLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if stats.practice.rounds > 0 {
                Text(stats.recordSummaryLine(for: .practice))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            } else {
                Text(L10n.t("stats.empty.entertainment"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(L10n.t("stats.entertainmentNote"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        } header: {
            Text(L10n.t("stats.section.entertainment"))
        } footer: {
            Text(L10n.t("stats.footer.entertainment"))
        }
    }
}
