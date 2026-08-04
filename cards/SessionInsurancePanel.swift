//
//  SessionInsurancePanel.swift
//  cards
//
//  P6+：庄家明牌为 A 时的保险决策面板（买半注 / 不买）。
//

import SwiftUI

struct SessionInsurancePanel: View {
    let balance: Int
    let mainBet: Int
    let insuranceAmount: Int
    let canBuy: Bool
    var buyDisabledReason: String? = nil
    let onBuy: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text(L10n.t("insurance.title"))
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text(L10n.t("insurance.upcardAce"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(L10n.t("insurance.rulesDetail"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(L10n.format("insurance.balanceStakeFormat", balance, mainBet))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .accessibilityLabel(
                                L10n.format("insurance.a11y.balanceStakeFormat", balance, mainBet)
                            )
                        Text(L10n.format("insurance.amountFormat", insuranceAmount))
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .accessibilityLabel(
                                L10n.format("insurance.a11y.amountFormat", insuranceAmount)
                            )
                        Text(ChipRules.insuranceOddsLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                Button {
                    GameFeedback.shared.buttonTap()
                    onBuy()
                } label: {
                    Text(L10n.t("insurance.buy"))
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
                .disabled(!canBuy)
                .opacity(canBuy ? 1 : 0.55)
                .accessibilityHint(
                    canBuy
                        ? L10n.t("insurance.a11y.buyHint")
                        : (buyDisabledReason ?? L10n.t("insurance.disabled.unavailable"))
                )

                Button {
                    GameFeedback.shared.buttonTap()
                    onDecline()
                } label: {
                    Text(L10n.t("insurance.decline"))
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityHint(L10n.t("insurance.a11y.declineHint"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)
            .background(.bar)
        }
    }
}
