//
//  SessionBetPanel.swift
//  cards
//
//  D10：开局前下注子视图（含发牌前全下）。
//

import SwiftUI

struct SessionBetPanel: View {
    let balance: Int
    @Binding var draftBet: Int
    let showRestoreHint: Bool
    let canConfirm: Bool
    /// 一副牌残局等：全下按钮用强调文案「强制全下」。
    let emphasizeForcedAllIn: Bool
    let onClear: () -> Void
    let onAddChip: (Int) -> Void
    let onAddRemaining: () -> Void
    let onAllIn: () -> Void
    let onConfirm: () -> Void

    private var remainingAdd: Int {
        ChipRules.remainingDraftAddAmount(draftBet: draftBet, balance: balance)
    }

    private var canAllIn: Bool {
        ChipRules.canPreDealAllIn(balance: balance) && draftBet < balance
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("下注")
                    .font(.title2.weight(.semibold))
                Text(draftBet == 0
                     ? "余额 \(balance)"
                     : "余额 \(balance) · 注 \(draftBet)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if showRestoreHint {
                    Text(ChipRules.restoreAfterInterruptHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                ForEach(ChipRules.betChipValues, id: \.self) { value in
                    Button {
                        GameFeedback.shared.buttonTap()
                        onAddChip(value)
                    } label: {
                        Text("+\(value)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!(value > 0 && draftBet + value <= balance))
                }
            }

            HStack(spacing: 16) {
                Button("清空") {
                    GameFeedback.shared.buttonTap()
                    onClear()
                }
                .font(.subheadline.weight(.semibold))
                .disabled(draftBet == 0)

                Spacer(minLength: 0)

                // 仅当剩余不是现有筹码档（零头）时显示，避免与 +100/+200/+500 重复。
                if remainingAdd > 0 {
                    Button {
                        GameFeedback.shared.buttonTap()
                        onAddRemaining()
                    } label: {
                        Text("余下全部 +\(remainingAdd)")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            Button {
                GameFeedback.shared.buttonTap()
                onAllIn()
            } label: {
                Text(emphasizeForcedAllIn ? "强制全下" : "全下")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(emphasizeForcedAllIn ? .orange : .red.opacity(0.85))
            .disabled(!canAllIn)
            .opacity(canAllIn ? 1 : 0.55)

            Spacer(minLength: 8)

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
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
