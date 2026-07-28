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
            return "已选筹码时全下不可用，可先清空"
        }
        return nil
    }

    private var balanceSummary: String {
        draftBet == 0
            ? "余额 \(balance)，请选一档"
            : "余额 \(balance)，注码 \(draftBet)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("下注")
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text(draftBet == 0
                             ? "余额 \(balance) · 请选一档"
                             : "余额 \(balance) · 注 \(draftBet)")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(balanceSummary)
                        Text("三档单选，选好后确认发牌")
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
                            .accessibilityLabel("筹码档 \(value)")
                            .accessibilityValue(selected ? "已选中" : (enabled ? "未选中" : "余额不足"))
                            .accessibilityHint(enabled ? "点选作为本局注码" : "余额不足以选择该档")
                        }
                    }

                    HStack(spacing: 16) {
                        Button("清空") {
                            GameFeedback.shared.buttonTap()
                            onClear()
                        }
                        .font(.subheadline.weight(.semibold))
                        .disabled(draftBet == 0)
                        .accessibilityHint(draftBet == 0 ? "当前未选注码" : "清除已选注码")

                        if showsRepeatLastBet {
                            Button(lastBetAmount > 0 ? "同上局 \(lastBetAmount)" : "同上局") {
                                GameFeedback.shared.buttonTap()
                                onRepeatLastBet()
                            }
                            .font(.subheadline.weight(.semibold))
                            .disabled(!canRepeatLastBet)
                            .accessibilityHint(
                                canRepeatLastBet
                                    ? "使用上局注码 \(lastBetAmount)"
                                    : "暂无可用的上局注码"
                            )
                        }

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 6) {
                        Button {
                            GameFeedback.shared.buttonTap()
                            onAllIn()
                        } label: {
                            Text(emphasizeForcedAllIn && allInUnlocked ? "强制全下" : "全下")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(emphasizeForcedAllIn && canAllIn ? .orange : .red.opacity(0.85))
                        .disabled(!canAllIn)
                        .opacity(canAllIn ? 1 : 0.45)
                        .accessibilityLabel(emphasizeForcedAllIn && allInUnlocked ? "强制全下" : "全下")
                        .accessibilityHint(canAllIn ? "将全部余额作为注码" : (allInDisabledReason ?? "当前不可用"))

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
                Text("确认并发牌")
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
            .accessibilityHint(canConfirm ? "确认注码并开始发牌" : "请先选择有效注码")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
