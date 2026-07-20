//
//  SettingsView.swift
//  cards
//
//  E2：设置页（默认副牌 / 切牌 / 桌限只读 / 音效触觉）。
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
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
                        flashHint()
                    }

                    Toggle("切牌（渗透率）", isOn: $settings.cutCardEnabled)
                        .onChange(of: settings.cutCardEnabled) { _, _ in
                            flashHint()
                        }
                    Text(settings.cutCardEnabled
                         ? "开启后按 50%–75% 切牌点局间重洗。"
                         : "关闭后每局打完下一局必整副重洗（无渗透）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("牌局")
                } footer: {
                    if let changeHint {
                        Text(changeHint)
                            .foregroundStyle(.orange)
                    } else {
                        Text(AppSettings.appliesNextRoundHint)
                    }
                }

                Section("桌限（只读）") {
                    Text(settings.tableLimitsSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("本版本不支持修改桌限数值。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Section("反馈") {
                    Toggle("音效", isOn: $settings.soundEnabled)
                    Toggle("触觉", isOn: $settings.hapticsEnabled)
                    Text("音效文件放入 Sounds/ 后自动播放；缺文件时静默跳过。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func flashHint() {
        withAnimation(.easeInOut(duration: 0.2)) {
            changeHint = AppSettings.appliesNextRoundHint
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
