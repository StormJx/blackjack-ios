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
            .navigationTitle("战绩")
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
                    "\(stage.title)，起始筹码你 \(stage.playerStart)，庄家 \(stage.dealerStart)"
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
                Text("尚无闯关对局记录。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } header: {
            Text("闯关模式")
        } footer: {
            Text("新开闯关会话按已解锁最高关给予双方起始筹码。卡背解锁也主要看闯关表现。")
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
                    "\(stage.title)，起始筹码你 \(stage.playerStart)，庄家 \(stage.dealerStart)"
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
                Text("尚无娱乐对局记录。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text("娱乐胜负不计入闯关成就。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        } header: {
            Text("娱乐模式")
        } footer: {
            Text("新开娱乐会话按当前阶给予起始筹码与注码三档；玩法道具仅娱乐可用。")
        }
    }
}
