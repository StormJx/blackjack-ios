//
//  SessionBetPanel.swift
//  cards
//
//  D10：开局前下注子视图。
//

import SwiftUI

struct SessionBetPanel: View {
    let balance: Int
    @Binding var draftBet: Int
    let showRestoreHint: Bool
    let canConfirm: Bool
    let onClear: () -> Void
    let onAddChip: (Int) -> Void
    let onAddRemaining: () -> Void
    let onConfirm: () -> Void

    private var remainingAdd: Int {
        ChipRules.remainingDraftAddAmount(draftBet: draftBet, balance: balance)
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

                Button {
                    GameFeedback.shared.buttonTap()
                    onAddRemaining()
                } label: {
                    Text(remainingAdd > 0 ? "余下全部 +\(remainingAdd)" : "余下全部")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(remainingAdd == 0)
            }

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
