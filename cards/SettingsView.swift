//
//  SettingsView.swift
//  cards
//
//  E2 / P4 / C1：设置页（牌副 / 切牌 / 桌限预设 / 卡背 / 音效触觉）。
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var cosmetics: CosmeticsStore
    @State private var changeHint: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("默认牌副", selection: $settings.defaultPracticeMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Text(mode.pickerLabel).tag(mode)
                        }
                    }
                    .onChange(of: settings.defaultPracticeMode) { _, _ in
                        flashHint(AppSettings.appliesNextRoundHint)
                    }

                    Toggle("切牌（渗透率）", isOn: $settings.cutCardEnabled)
                        .onChange(of: settings.cutCardEnabled) { _, _ in
                            flashHint(AppSettings.appliesNextRoundHint)
                        }
                    Text(settings.cutCardEnabled
                         ? "闯关：开启后按 50%–75% 切牌点局间重洗。"
                         : "闯关：关闭后每局打完下一局必整副重洗（无渗透）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("娱乐模式固定「真实切牌」（不受本开关影响）；仪式感切牌后续再做。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    Text("牌局")
                } footer: {
                    if let changeHint {
                        Text(changeHint)
                            .foregroundStyle(.orange)
                    } else {
                        Text("默认牌副用于主页开局；\(AppSettings.appliesNextRoundHint)")
                    }
                }

                Section {
                    Picker("桌限方案", selection: $settings.tableLimitPreset) {
                        ForEach(TableLimitPreset.allCases) { preset in
                            Text("\(preset.title)：\(preset.summary)").tag(preset)
                        }
                    }
                    .onChange(of: settings.tableLimitPreset) { _, _ in
                        flashHint(AppSettings.tableLimitsApplyNextSessionHint)
                    }
                    Text("闯关模式采用此桌限；娱乐模式注码随娱乐阶梯自动提升，不受本项影响。改后须返回主页再开闯关新局才生效。详情见主页「帮助说明」。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("桌限")
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
                    Text("音效来自 Sounds/ 六基名文件（当前为程序合成增强版）；关闭开关后不播放；缺文件时静默跳过。可替换为录音级 wav/mp3。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
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

    private func flashHint(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            changeHint = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    changeHint = nil
                }
            }
        }
    }
}
