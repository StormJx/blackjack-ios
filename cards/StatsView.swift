//
//  StatsView.swift
//  cards
//
//  战绩摘要（筹码与分模式胜负）；成就详见 AchievementsView。
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: StatsStore

    var body: some View {
        NavigationStack {
            Group {
                if stats.hasAnyHistory {
                    List {
                        Section("挑战模式") {
                            Text(stats.recordSummaryLine(for: .challenge))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                            Text(stats.chipsSummaryLine())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Section("快速练习") {
                            Text(stats.recordSummaryLine(for: .practice))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                            Text("练习胜负不计入挑战成就。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "尚无战绩",
                        systemImage: "chart.bar",
                        description: Text("完成几局挑战或快速练习后，这里会显示累计战绩。")
                    )
                }
            }
            .navigationTitle("战绩")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
