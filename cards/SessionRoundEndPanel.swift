//
//  SessionRoundEndPanel.swift
//  cards
//
//  D10：局末结果 / 破产回主页子视图。
//

import SwiftUI

struct SessionRoundEndPanel: View {
    let isSessionOver: Bool
    let sessionEndReason: SessionEndReason?
    let outcomeMessage: String
    let outcome: RoundOutcome?
    let settlement: SettlementResult?
    let balance: Int
    let dealerBank: Int
    let shoeStatusLine: String
    let onReturnHome: () -> Void
    let onContinue: () -> Void

    private var statusColor: Color {
        outcome?.statusColor ?? .secondary
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(isSessionOver ? "本局游戏结束" : "本局结束")
                    .font(.title2.weight(.semibold))
                if let reason = sessionEndReason {
                    Text(reason.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(reason == .dealerBroke ? .green : .red)
                    Text(reason.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text(outcomeMessage)
                    .font(isSessionOver ? .body.weight(.semibold) : .title3.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            VStack(spacing: 8) {
                if let settlement {
                    Text("本局盈亏 \(settlement.netChangeLabel)")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(settlementNetColor(settlement.netChange))
                    if let odds = settlement.oddsLabel {
                        Text(odds)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let partial = settlement.partialPayoutLabel {
                        Text(partial)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                    Text("你 \(settlement.balanceAfter) · 庄家 \(settlement.dealerBankAfter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text("你 \(balance) · 庄家 \(dealerBank)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Text(shoeStatusLine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            .padding(.top, 16)

            Spacer(minLength: 24)

            if isSessionOver {
                Button {
                    GameFeedback.shared.buttonTap()
                    onReturnHome()
                } label: {
                    Text("返回主页")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
            } else {
                Button {
                    GameFeedback.shared.buttonTap()
                    onContinue()
                } label: {
                    Text("继续")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func settlementNetColor(_ net: Int) -> Color {
        if net > 0 { return .green }
        if net < 0 { return .red }
        return .orange
    }
}
