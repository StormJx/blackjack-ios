//
//  HelpView.swift
//  cards
//
//  欢迎页「帮助说明」：规则、模式、设置入口指引（主页只保留入口按钮）。
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(L10n.t("help.body.positioning"))
                } header: {
                    Text(L10n.t("help.section.positioning"))
                }

                Section {
                    Text(L10n.t("help.body.rules"))
                } header: {
                    Text(L10n.t("help.section.rules"))
                }

                Section {
                    Text(L10n.t("help.body.challenge1"))
                    Text(L10n.t("help.body.challenge2"))
                } header: {
                    Text(L10n.t("help.section.challenge"))
                }

                Section {
                    Text(L10n.t("help.body.entertainment1"))
                    Text(L10n.t("help.body.entertainment2"))
                } header: {
                    Text(L10n.t("help.section.entertainment"))
                }

                Section {
                    Text(L10n.t("help.body.meta1"))
                    Text(L10n.t("help.body.meta2"))
                } header: {
                    Text(L10n.t("help.section.meta"))
                }

                Section {
                    Text(L10n.t("help.body.note"))
                    Text(L10n.t("help.body.privacy"))
                } header: {
                    Text(L10n.t("help.section.note"))
                }
            }
            .navigationTitle(L10n.t("help.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("help.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
