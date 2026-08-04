//
//  SettingsView.swift
//  cards
//
//  E2 / P4 / C1 / P5 / F1 / UX9：设置页（牌副 / 切牌三态 / 桌限 / 全下解锁 / 卡背 / 音效触觉）。
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var cosmetics: CosmeticsStore
    /// UX9：会话级设置刚被改动时短暂高亮「生效时机」提示。
    @State private var highlightSessionLockedHint = false
    @State private var hintClearTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        Text(AppSettings.sessionLockedSettingsHint)
                            .font(.footnote)
                            .foregroundStyle(highlightSessionLockedHint ? Color.orange : .secondary)
                            .accessibilityLabel(AppSettings.sessionLockedSettingsHint)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(highlightSessionLockedHint ? Color.orange : .secondary)
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text(L10n.t("settings.section.timing"))
                } footer: {
                    Text(L10n.t("settings.footer.immediate"))
                }

                Section {
                    Picker(L10n.t("settings.picker.defaultDeck"), selection: $settings.defaultPracticeMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Text(mode.pickerLabel).tag(mode)
                        }
                    }
                    .onChange(of: settings.defaultPracticeMode) { _, _ in
                        flashSessionLockedHint()
                    }

                    Picker(L10n.t("settings.picker.cutCard"), selection: $settings.cutCardMode) {
                        ForEach(CutCardMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .onChange(of: settings.cutCardMode) { _, _ in
                        flashSessionLockedHint()
                    }
                    Text(settings.cutCardMode.settingsDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("settings.cut.entertainmentFixed"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    Text(L10n.t("settings.section.deal"))
                } footer: {
                    Text(L10n.t("settings.footer.deal"))
                }

                Section {
                    Picker(L10n.t("settings.picker.tableLimit"), selection: $settings.tableLimitPreset) {
                        ForEach(TableLimitPreset.allCases) { preset in
                            Text("\(preset.title)：\(preset.summary)").tag(preset)
                        }
                    }
                    .onChange(of: settings.tableLimitPreset) { _, _ in
                        flashSessionLockedHint()
                    }
                    Text(L10n.t("settings.tableLimit.caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(L10n.t("settings.section.tableLimit"))
                }

                Section {
                    Stepper(
                        value: $settings.preDealAllInUnlockRounds,
                        in: ChipRules.preDealAllInUnlockRoundsRange
                    ) {
                        Text(L10n.format("settings.allInUnlockRoundsFormat", settings.preDealAllInUnlockRounds))
                    }
                    .onChange(of: settings.preDealAllInUnlockRounds) { _, _ in
                        flashSessionLockedHint()
                    }
                    Text(
                        settings.preDealAllInUnlockRounds == 0
                            ? L10n.t("settings.allInUnlock.zero")
                            : L10n.format("settings.allInUnlock.nonzeroFormat", settings.preDealAllInUnlockRounds)
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(L10n.t("settings.section.allIn"))
                }

                Section {
                    ForEach(CardBackStyle.allCases) { style in
                        cardBackRow(style)
                    }
                } header: {
                    Text(L10n.t("settings.section.cardBack"))
                } footer: {
                    Text(L10n.t("settings.footer.cardBack"))
                }

                Section(L10n.t("settings.section.feedback")) {
                    Toggle(L10n.t("settings.toggle.sound"), isOn: $settings.soundEnabled)
                    Toggle(L10n.t("settings.toggle.haptics"), isOn: $settings.hapticsEnabled)
                    Toggle(L10n.t("settings.toggle.confirmAllIn"), isOn: $settings.confirmMidHandAllIn)
                    Text(L10n.t("settings.footer.feedback"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.t("settings.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.2), value: highlightSessionLockedHint)
            .onDisappear {
                hintClearTask?.cancel()
                hintClearTask = nil
            }
        }
    }

    private func cardBackRow(_ style: CardBackStyle) -> some View {
        let owned = cosmetics.owns(style)
        let selected = cosmetics.selectedBack == style
        return Button {
            guard owned else { return }
            GameFeedback.shared.buttonTap()
            cosmetics.select(style)
        } label: {
            HStack(spacing: 12) {
                PlayingCardView(face: .faceDown, width: 44, height: 62, cardBack: style)
                    .opacity(owned ? 1 : 0.55)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .font(.headline)
                        .foregroundStyle(owned ? .primary : .secondary)
                    if owned {
                        Text(selected ? L10n.t("settings.cardBack.inUse") : L10n.t("settings.cardBack.tapToSelect"))
                            .font(.caption)
                            .foregroundStyle(selected ? .green : .secondary)
                    } else {
                        Text(style.unlockHint)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if !owned {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(
            "\(style.title)，\(owned ? (selected ? L10n.t("settings.cardBack.inUse") : L10n.t("settings.cardBack.unlocked")) : L10n.t("settings.cardBack.locked"))"
        )
    }

    private func flashSessionLockedHint() {
        hintClearTask?.cancel()
        highlightSessionLockedHint = true
        hintClearTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                highlightSessionLockedHint = false
            }
        }
    }
}
