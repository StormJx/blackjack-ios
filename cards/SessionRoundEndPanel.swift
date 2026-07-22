//
//  SessionRoundEndPanel.swift
//  cards
//
//  D10 / E1：局末结果（挑战含筹码；快速含会话统计）。
//

import SwiftUI

struct SessionRoundEndPanel: View {
    let playStyle: PlayStyle
    let isSessionOver: Bool
    let sessionEndReason: SessionEndReason?
    let outcomeMessage: String
    let outcome: RoundOutcome?
    let settlement: SettlementResult?
    let balance: Int
    let dealerBank: Int
    let shoeStatusLine: String
    /// 快速模式本会话统计；挑战模式传 nil。
    let fastStats: FastSessionStats?
    /// 成就轻提示（不挡操作）。
    let achievementToast: String?
    let onReturnHome: () -> Void
    let onContinue: () -> Void

    @State private var settlementPulse = false

    private var statusColor: Color {
        outcome?.statusColor ?? .secondary
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(titleText)
                    .font(.title2.weight(.semibold))
                if let reason = sessionEndReason, isSessionOver {
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

                if let achievementToast {
                    Text(achievementToast)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            VStack(spacing: 8) {
                if playStyle.showsChips {
                    challengeSettlementBlock
                } else if let fastStats {
                    Text(fastStats.summaryLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                }
                Text(shoeStatusLine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            .padding(.top, 16)
            .scaleEffect(settlementPulse ? 1.04 : 1)
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: settlementPulse)

            Spacer(minLength: 24)

            if playStyle.showsChips && isSessionOver {
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
                    Text(playStyle.continueButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            settlementPulse = true
            Task {
                try? await Task.sleep(nanoseconds: 280_000_000)
                await MainActor.run { settlementPulse = false }
            }
        }
    }

    private var titleText: String {
        if isSessionOver {
            return "本局游戏结束"
        }
        return "本局结束"
    }

    @ViewBuilder
    private var challengeSettlementBlock: some View {
        if let settlement {
            Text("本局盈亏 \(settlement.netChangeLabel)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(settlementNetColor(settlement.netChange))
                .contentTransition(.numericText())
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
    }

    private func settlementNetColor(_ net: Int) -> Color {
        if net > 0 { return .green }
        if net < 0 { return .red }
        return .orange
    }
}
