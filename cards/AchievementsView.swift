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
                Picker(L10n.t("achievements.pickerMode"), selection: $scope) {
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
                            Text(L10n.t("achievements.entertainmentNote"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text(L10n.t("achievements.statsSummary"))
                    }

                    if scope == .practice {
                        Section {
                            ForEach(PropID.allCases) { prop in
                                propRow(prop)
                            }
                        } header: {
                            Text(L10n.t("achievements.props"))
                        } footer: {
                            Text(L10n.t("achievements.propsFooter"))
                        }
                    } else {
                        Section {
                            Text(L10n.t("achievements.propsChallengeNote"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text(L10n.t("achievements.props"))
                        }
                    }

                    Section {
                        let ids = AchievementID.ids(in: scope)
                        if ids.isEmpty {
                            Text(L10n.t("achievements.empty"))
                        } else {
                            ForEach(ids) { id in
                                achievementRow(id)
                            }
                        }
                    } header: {
                        let unlocked = AchievementID.ids(in: scope)
                            .filter { stats.unlockedIDs.contains($0) }.count
                        let total = AchievementID.ids(in: scope).count
                        Text(L10n.format("achievements.countFormat", unlocked, total))
                    } footer: {
                        Text(scope == .challenge
                             ? L10n.t("achievements.footer.challenge")
                             : L10n.t("achievements.footer.entertainment"))
                    }
                }
            }
            .navigationTitle(L10n.t("achievements.navTitle"))
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
                        Text(L10n.t("achievements.goChallengeUnlock"))
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
                    Text(L10n.t("achievements.propUnlockedEntertainment"))
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if id.unlocksViaChallenge {
                    Text(L10n.format("achievements.goChallengeUnlockFormat", id.unlockHint))
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
            L10n.format(
                "achievements.a11y.rowFormat",
                id.title,
                owned
                    ? L10n.t("achievements.state.unlocked")
                    : (id.unlocksViaChallenge
                        ? L10n.t("achievements.state.lockedChallenge")
                        : L10n.t("achievements.state.locked"))
            )
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
                    Text(L10n.format("achievements.progressFormat", progress, target))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L10n.format(
                "achievements.a11y.rowFormat",
                id.title,
                unlocked
                    ? L10n.t("achievements.state.unlocked")
                    : L10n.t("achievements.state.locked")
            )
        )
    }
}
