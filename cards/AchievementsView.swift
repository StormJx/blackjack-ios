//
//  AchievementsView.swift
//  cards
//
//  成就页签：挑战 / 练习分栏，展示已解锁与未解锁。
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var stats: StatsStore
    @State private var scope: AchievementScope = .challenge

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("模式", selection: $scope) {
                    ForEach(AchievementScope.allCases) { s in
                        Text(s.tabTitle).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                List {
                    Section {
                        Text(stats.recordSummaryLine(for: scope))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        if scope == .challenge {
                            Text(stats.chipsSummaryLine())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        } else {
                            Text("练习对局不计入挑战成就；完成练习专属成就可在此查看。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("战绩摘要")
                    }

                    Section {
                        let ids = AchievementID.ids(in: scope)
                        if ids.isEmpty {
                            Text("暂无成就")
                        } else {
                            ForEach(ids) { id in
                                achievementRow(id)
                            }
                        }
                    } header: {
                        let unlocked = AchievementID.ids(in: scope)
                            .filter { stats.unlockedIDs.contains($0) }.count
                        let total = AchievementID.ids(in: scope).count
                        Text("成就 \(unlocked)/\(total)")
                    } footer: {
                        Text(scope == .challenge
                             ? "仅「挑战庄家」对局会计入本栏成就。"
                             : "仅「快速练习」对局会计入本栏成就。")
                    }
                }
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func achievementRow(_ id: AchievementID) -> some View {
        let unlocked = stats.unlockedIDs.contains(id)
        let input = stats.progressInput(for: id.scope)
        let progress = AchievementEvaluator.displayedProgress(for: id, progress: input)
        let target = id.progressTarget

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                .foregroundStyle(unlocked ? .green : .secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(id.title)
                    .font(.headline)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(id.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if target > 1 {
                    ProgressView(value: Double(progress), total: Double(target))
                    Text("\(progress) / \(target)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(id.title)，\(unlocked ? "已解锁" : "未解锁")")
    }
}
