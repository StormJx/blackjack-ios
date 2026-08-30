//
//  AppLanguagePreference.swift
//  cards
//
//  界面语言：跟随系统，或强制中文 / English。与 String Catalog 两套文案并存。
//

import Foundation

enum AppLanguagePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L10n.t("settings.language.system")
        case .chinese: return L10n.t("settings.language.chinese")
        case .english: return L10n.t("settings.language.english")
        }
    }

    /// `nil` 表示跟随系统；否则为 Catalog 语言码。
    var catalogLanguage: String? {
        switch self {
        case .system: return nil
        case .chinese: return "zh-Hans"
        case .english: return "en"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        case .chinese: return Locale(identifier: "zh-Hans")
        case .english: return Locale(identifier: "en")
        }
    }
}
