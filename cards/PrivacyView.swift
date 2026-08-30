//
//  PrivacyView.swift
//  cards
//
//  应用内隐私说明：不采集、不追踪、进度仅存本机。
//

import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(L10n.t("privacy.body.collect"))
                    Text(L10n.t("privacy.body.storage"))
                    Text(L10n.t("privacy.body.ads"))
                    Text(L10n.t("privacy.body.age"))
                } header: {
                    Text(L10n.t("privacy.section.summary"))
                }

                Section {
                    Text(L10n.t("privacy.body.positioning"))
                } header: {
                    Text(L10n.t("privacy.section.product"))
                }
            }
            .navigationTitle(L10n.t("privacy.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("privacy.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
