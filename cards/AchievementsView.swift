//
//  AchievementsView.swift
//  cards
//
//  成就页签：闯关 / 娱乐分栏；道具区仅娱乐 tab（UX4）。
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var stats: StatsStore
    @ObservedObject var props: PropStore
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
                            Text("娱乐对局不计入闯关成就；完成娱乐专属成就可在此查看。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("战绩摘要")
                    }

                    if scope == .practice {
                        Section {
                            ForEach(PropID.allCases) { prop in
                                propRow(prop)
                            }
                        } header: {
                            Text("道具")
                        } footer: {
                            Text("玩法道具仅「娱乐模式」对局可用。部分道具需先在闯关解锁成就。卡背在设置页选用。")
                        }
                    } else {
                        Section {
                            Text("玩法道具请切换到「娱乐」页签查看；闯关对局中不可使用道具。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text("道具")
                        }
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
                             ? "仅「闯关挑战」对局会计入本栏成就。"
                             : "仅「娱乐模式」对局会计入本栏成就。")
                    }
                }
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func propRow(_ id: PropID) -> some View {
        let owned = props.owns(id)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: owned ? "gift.fill" : "gift")
                .foregroundStyle(owned ? .orange : .secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(id.title)
                        .font(.headline)
                        .foregroundStyle(owned ? .primary : .secondary)
                    if !owned, id.unlocksViaChallenge {
                        Text("去闯关解锁")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.orange.opacity(0.14))
                            )
                    }
                }
                Text(id.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if owned {
                    Text("已永久解锁 · 仅娱乐模式可用")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if id.unlocksViaChallenge {
                    Text("去闯关解锁 · \(id.unlockHint)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(id.unlockHint)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(id.title)，\(owned ? "已解锁" : (id.unlocksViaChallenge ? "未解锁，去闯关解锁" : "未解锁"))"
        )
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
