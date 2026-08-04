//
//  SessionRoundEndPanel.swift
//  cards
//
//  D10 / E1 / UX3 / UX5 / UX7：局末结果、解锁卡片、娱乐会话统计、可收起看牌面。
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
    /// 娱乐模式本会话胜负统计；闯关传 nil。
    let fastStats: FastSessionStats?
    /// UX3：本局解锁队列（成就 / 道具 / 卡背等短标题）。
    let unlockNotices: [String]
    let onReturnHome: () -> Void
    let onContinue: () -> Void
    /// UX7：暂时收起面板查看牌面。
    var onPeekTable: (() -> Void)? = nil

    @State private var settlementPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var statusColor: Color {
        outcome?.statusColor ?? .secondary
    }

    private var primaryButtonTitle: String {
        if playStyle.showsChips && isSessionOver {
            return L10n.t("roundEnd.returnHome")
        }
        return playStyle.continueButtonTitle
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Text(titleText)
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Spacer(minLength: 0)
                        if onPeekTable != nil, !isSessionOver {
                            Button(L10n.t("roundEnd.viewTable")) {
                                GameFeedback.shared.buttonTap()
                                onPeekTable?()
                            }
                            .font(.subheadline.weight(.semibold))
                            .accessibilityHint(L10n.t("roundEnd.a11y.peekHint"))
                        }
                    }

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
                        .accessibilityLabel(L10n.format("roundEnd.a11y.outcomeFormat", outcomeMessage))

                    if !unlockNotices.isEmpty {
                        unlockCardsBlock
                    }

                    VStack(spacing: 8) {
                        if playStyle.showsChips {
                            challengeSettlementBlock
                        }
                        if let fastStats {
                            Text(fastStats.summaryLine)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .multilineTextAlignment(.center)
                                .accessibilityLabel(fastStats.summaryLine)
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
                        Text(L10n.t("roundEnd.returnHome"))
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
            .accessibilityHint(
                isSessionOver
                    ? L10n.t("roundEnd.a11y.endHint")
                    : L10n.t("roundEnd.a11y.continueHint")
            )
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
            return L10n.t("roundEnd.title.session")
        }
        return L10n.t("roundEnd.title.round")
    }

    private var unlockCardsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("roundEnd.unlocks"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(unlockNotices.enumerated()), id: \.offset) { _, title in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L10n.format("roundEnd.a11y.unlockFormat", title))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private var challengeSettlementBlock: some View {
        if let settlement {
            let netLine = L10n.format("roundEnd.netFormat", settlement.netChangeLabel)
            Text(netLine)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(settlementNetColor(settlement.netChange))
                .contentTransition(.numericText())
                .accessibilityLabel(netLine)
            if let odds = settlement.oddsLabel {
                Text(odds)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if let insurance = settlement.insuranceLabel {
                Text(insurance)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(insurance)
            }
            if let partial = settlement.partialPayoutLabel {
                Text(partial)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
            Text(
                L10n.format(
                    "roundEnd.banksFormat",
                    settlement.balanceAfter,
                    settlement.dealerBankAfter
                )
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(
                    L10n.format(
                        "roundEnd.a11y.banksFormat",
                        settlement.balanceAfter,
                        settlement.dealerBankAfter
                    )
                )
        } else {
            Text(L10n.format("roundEnd.banksFormat", balance, dealerBank))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(
                    L10n.format("roundEnd.a11y.banksFormat", balance, dealerBank)
                )
        }
    }

    private func settlementNetColor(_ net: Int) -> Color {
        if net > 0 { return .green }
        if net < 0 { return .red }
        return .orange
    }
}
