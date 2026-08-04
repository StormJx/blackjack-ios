//
//  SessionBetPanel.swift
//  cards
//
//  开局前下注：三档单选 + 条件解锁的全下。
//  P8-1：可滚动 + VoiceOver + 大字体下主按钮可达。
//

import SwiftUI

struct SessionBetPanel: View {
    let balance: Int
    @Binding var draftBet: Int
    let showRestoreHint: Bool
    let canConfirm: Bool
    /// 本会话已完成局数（开局全下解锁用；门槛见设置 / ActivePreDealAllInUnlock）。
    let sessionRoundsCompleted: Int
    /// 一副牌残局等：全下按钮用强调文案「强制全下」（仍须已解锁）。
    let emphasizeForcedAllIn: Bool
    /// P3：仅娱乐显示「同上局」。
    var showsRepeatLastBet: Bool = false
    var lastBetAmount: Int = 0
    var canRepeatLastBet: Bool = false
    let onClear: () -> Void
    let onSelectChip: (Int) -> Void
    let onAllIn: () -> Void
    var onRepeatLastBet: () -> Void = {}
    let onConfirm: () -> Void

    private var allInUnlocked: Bool {
        sessionRoundsCompleted >= ChipRules.preDealAllInUnlockCompletedRounds
    }

    private var canAllIn: Bool {
        ChipRules.isPreDealAllInEnabled(
            balance: balance,
            sessionRoundsCompleted: sessionRoundsCompleted,
            draftBet: draftBet
        )
    }

    private var allInDisabledReason: String? {
        if !ChipRules.canPreDealAllIn(balance: balance) {
            return nil
        }
        if let hint = ChipRules.preDealAllInLockHint(sessionRoundsCompleted: sessionRoundsCompleted) {
            return hint
        }
        if draftBet > 0 {
            return L10n.t("bet.allInDisabledWhenSelected")
        }
        return nil
    }

    private var balanceLine: String {
        draftBet == 0
            ? L10n.format("bet.balancePickFormat", balance)
            : L10n.format("bet.balanceBetFormat", balance, draftBet)
    }

    private var balanceSummary: String {
        draftBet == 0
            ? L10n.format("bet.a11y.balancePickFormat", balance)
            : L10n.format("bet.a11y.balanceBetFormat", balance, draftBet)
    }

    private var allInTitle: String {
        emphasizeForcedAllIn && allInUnlocked
            ? L10n.t("bet.forceAllIn")
            : L10n.t("bet.allIn")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text(L10n.t("bet.title"))
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text(balanceLine)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(balanceSummary)
                        Text(L10n.t("bet.hint.pickChips"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        if showRestoreHint {
                            Text(ChipRules.restoreAfterInterruptHint)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                                .accessibilityLabel(ChipRules.restoreAfterInterruptHint)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        ForEach(ChipRules.betChipValues, id: \.self) { value in
                            let selected = draftBet == value
                            let enabled = ChipRules.canSelectBetChip(value, balance: balance)
                            Button {
                                GameFeedback.shared.buttonTap()
                                onSelectChip(value)
                            } label: {
                                Text("\(value)")
                                    .font(.body.weight(selected ? .bold : .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selected ? .green : .secondary.opacity(0.35))
                            .disabled(!enabled)
                            .opacity(enabled ? 1 : 0.45)
                            .accessibilityLabel(L10n.format("bet.a11y.chipFormat", value))
                            .accessibilityValue(
                                selected
                                    ? L10n.t("bet.a11y.chipSelected")
                                    : (enabled
                                        ? L10n.t("bet.a11y.chipUnselected")
                                        : L10n.t("bet.a11y.chipInsufficient"))
                            )
                            .accessibilityHint(
                                enabled
                                    ? L10n.t("bet.a11y.chipHintSelect")
                                    : L10n.t("bet.a11y.chipHintInsufficient")
                            )
                        }
                    }

                    HStack(spacing: 16) {
                        Button(L10n.t("bet.clear")) {
                            GameFeedback.shared.buttonTap()
                            onClear()
                        }
                        .font(.subheadline.weight(.semibold))
                        .disabled(draftBet == 0)
                        .accessibilityHint(
                            draftBet == 0
                                ? L10n.t("bet.a11y.clearNoBet")
                                : L10n.t("bet.a11y.clearHint")
                        )

                        if showsRepeatLastBet {
                            Button(
                                lastBetAmount > 0
                                    ? L10n.format("bet.sameAsLastFormat", lastBetAmount)
                                    : L10n.t("bet.sameAsLast")
                            ) {
                                GameFeedback.shared.buttonTap()
                                onRepeatLastBet()
                            }
                            .font(.subheadline.weight(.semibold))
                            .disabled(!canRepeatLastBet)
                            .accessibilityHint(
                                canRepeatLastBet
                                    ? L10n.format("bet.a11y.repeatFormat", lastBetAmount)
                                    : L10n.t("bet.a11y.repeatUnavailable")
                            )
                        }

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 6) {
                        Button {
                            GameFeedback.shared.buttonTap()
                            onAllIn()
                        } label: {
                            Text(allInTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(emphasizeForcedAllIn && canAllIn ? .orange : .red.opacity(0.85))
                        .disabled(!canAllIn)
                        .opacity(canAllIn ? 1 : 0.45)
                        .accessibilityLabel(allInTitle)
                        .accessibilityHint(
                            canAllIn
                                ? L10n.t("bet.a11y.allInHint")
                                : (allInDisabledReason ?? L10n.t("disabled.unavailable"))
                        )

                        if let reason = allInDisabledReason {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            Button {
                GameFeedback.shared.buttonTap()
                onConfirm()
            } label: {
                Text(L10n.t("bet.confirmDeal"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
            .disabled(!canConfirm)
            .opacity(canConfirm ? 1 : 0.55)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .accessibilityHint(
                canConfirm
                    ? L10n.t("bet.a11y.confirmHint")
                    : L10n.t("bet.a11y.confirmDisabled")
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
