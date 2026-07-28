//
//  SessionRoundEndPanel.swift
//  cards
//
//  D10 / E1：局末结果（挑战含筹码；快速含会话统计）。
//  P8-1：可滚动 + VoiceOver + 大字体下主按钮可达。
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var statusColor: Color {
        outcome?.statusColor ?? .secondary
    }

    private var primaryButtonTitle: String {
        if playStyle.showsChips && isSessionOver {
            return "返回主页"
        }
        return playStyle.continueButtonTitle
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    Text(titleText)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
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
                        .accessibilityLabel("本局结果：\(outcomeMessage)")

                    if let achievementToast {
                        Text(achievementToast)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .accessibilityLabel(achievementToast)
                    }

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
                            .accessibilityLabel(shoeStatusLine)
                    }
                    .padding(.top, 8)
                    .scaleEffect((!reduceMotion && settlementPulse) ? 1.04 : 1)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.72),
                        value: settlementPulse
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Group {
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
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .accessibilityHint(isSessionOver ? "结束本会话并返回欢迎页" : "进入下一局下注")
            .accessibilityLabel(primaryButtonTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard !reduceMotion else { return }
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
                .accessibilityLabel("本局盈亏 \(settlement.netChangeLabel)")
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
                .accessibilityLabel(
                    "你的余额 \(settlement.balanceAfter)，庄家余额 \(settlement.dealerBankAfter)"
                )
        } else {
            Text("你 \(balance) · 庄家 \(dealerBank)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel("你的余额 \(balance)，庄家余额 \(dealerBank)")
        }
    }

    private func settlementNetColor(_ net: Int) -> Color {
        if net > 0 { return .green }
        if net < 0 { return .red }
        return .orange
    }
}
