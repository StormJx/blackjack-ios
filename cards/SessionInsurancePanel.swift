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
                        Text("保险")
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text("庄家明牌为 A")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("可买半注保险；庄家黑杰克时保险按 2:1 赔付，主注仍按胜负结算。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("余额 \(balance) · 主注 \(mainBet)")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .accessibilityLabel("余额 \(balance)，主注 \(mainBet)")
                        Text("保险 \(insuranceAmount)")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .accessibilityLabel("保险注码 \(insuranceAmount)")
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
                    Text("买保险")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
                .disabled(!canBuy)
                .opacity(canBuy ? 1 : 0.55)
                .accessibilityHint(canBuy ? "支付半注作为保险" : (buyDisabledReason ?? "当前不可买保险"))

                Button {
                    GameFeedback.shared.buttonTap()
                    onDecline()
                } label: {
                    Text("不买")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityHint("放弃保险，庄家将查看是否黑杰克")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)
            .background(.bar)
        }
    }
}
