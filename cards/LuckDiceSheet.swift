//
//  LuckDiceSheet.swift
//  cards
//
//  欢迎页小骰子：一键掷出 1–3 颗，点数高则标记今天手气好。
//

import SwiftUI

struct LuckDiceSheet: View {
    @ObservedObject var store: LuckDiceStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text(L10n.t("luck.prompt"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                diceFaces
                    .frame(minHeight: 64)

                Text(totalLine)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .monospacedDigit()

                Text(verdictLine)
                    .font(.headline)
                    .foregroundStyle(store.state.lastRollIsLucky ? Color.orange : Color.secondary)

                if store.state.roundsRemaining > 0 {
                    Text(L10n.format("luck.buffFormat", store.state.roundsRemaining))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Text(L10n.t("luck.challengeNote"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Picker(L10n.t("luck.diceCount"), selection: $store.diceCount) {
                    ForEach(1...LuckDiceRules.maxDice, id: \.self) { count in
                        Text(L10n.format("luck.diceCountFormat", count)).tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(L10n.t("luck.diceCount"))

                Button {
                    GameFeedback.shared.buttonTap()
                    store.roll()
                } label: {
                    Text(L10n.t("luck.roll"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(red: 0.92, green: 0.78, blue: 0.28))
                .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.12))

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle(L10n.t("luck.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var totalLine: String {
        guard !store.state.lastFaces.isEmpty else { return L10n.t("luck.waiting") }
        return L10n.format("luck.totalFormat", store.state.total)
    }

    private var verdictLine: String {
        guard !store.state.lastFaces.isEmpty else { return " " }
        return store.state.lastRollIsLucky ? L10n.t("luck.lucky") : L10n.t("luck.plain")
    }

    private var diceFaces: some View {
        let faces = store.state.lastFaces
        return HStack(spacing: 14) {
            if faces.isEmpty {
                ForEach(0..<store.diceCount, id: \.self) { _ in
                    Image(systemName: "die.face.1")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                }
            } else {
                ForEach(Array(faces.enumerated()), id: \.offset) { index, face in
                    Image(systemName: "die.face.\(face)")
                        .font(.system(size: 44))
                        .foregroundStyle(.primary)
                        .accessibilityLabel(L10n.format("luck.a11y.faceFormat", index + 1, face))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
