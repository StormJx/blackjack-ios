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
                    Text("生效时机")
                } footer: {
                    Text("音效、触觉、局内全下确认与卡背选用可立即生效。")
                }

                Section {
                    Picker("默认牌副", selection: $settings.defaultPracticeMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Text(mode.pickerLabel).tag(mode)
                        }
                    }
                    .onChange(of: settings.defaultPracticeMode) { _, _ in
                        flashSessionLockedHint()
                    }

                    Picker("切牌（闯关）", selection: $settings.cutCardMode) {
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
                    Text("娱乐模式固定「真实切牌」（不受本项影响）。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    Text("牌局")
                } footer: {
                    Text("默认牌副用于主页开局；切牌仅影响闯关。")
                }

                Section {
                    Picker("桌限方案", selection: $settings.tableLimitPreset) {
                        ForEach(TableLimitPreset.allCases) { preset in
                            Text("\(preset.title)：\(preset.summary)").tag(preset)
                        }
                    }
                    .onChange(of: settings.tableLimitPreset) { _, _ in
                        flashSessionLockedHint()
                    }
                    Text("闯关模式采用此桌限；娱乐模式注码随娱乐阶梯自动提升，不受本项影响。详情见主页「帮助说明」。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("桌限")
                }

                Section {
                    Stepper(
                        value: $settings.preDealAllInUnlockRounds,
                        in: ChipRules.preDealAllInUnlockRoundsRange
                    ) {
                        Text("全下解锁局数：\(settings.preDealAllInUnlockRounds)")
                    }
                    .onChange(of: settings.preDealAllInUnlockRounds) { _, _ in
                        flashSessionLockedHint()
                    }
                    Text(settings.preDealAllInUnlockRounds == 0
                         ? "开局下注页即可使用「全下」（闯关与娱乐共用）。"
                         : "本会话打满 \(settings.preDealAllInUnlockRounds) 局后，开局下注页解锁「全下」（闯关与娱乐共用）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("全下")
                }

                Section {
                    ForEach(CardBackStyle.allCases) { style in
                        cardBackRow(style)
                    }
                } header: {
                    Text("卡背")
                } footer: {
                    Text("外观不影响胜负；可在闯关与娱乐中共用。未解锁可预览，不可选用。")
                }

                Section("反馈") {
                    Toggle("音效", isOn: $settings.soundEnabled)
                    Toggle("触觉", isOn: $settings.hapticsEnabled)
                    Toggle("局内全下需确认", isOn: $settings.confirmMidHandAllIn)
                    Text("关闭后不播放音效；未配置音效文件时会静默跳过。「局内全下需确认」仅影响娱乐模式见牌后再全下。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
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
                        Text(selected ? "使用中" : "点击选用")
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
        .accessibilityLabel("\(style.title)，\(owned ? (selected ? "使用中" : "已解锁") : "未解锁")")
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
