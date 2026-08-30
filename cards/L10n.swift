//
//  L10n.swift
//  cards
//
//  L1：本地化入口。文案在 Localizable.xcstrings（源语言 zh-Hans，并含 en）。
//  - 语义化 key（如 welcome.appTitle），扩语言只改 Catalog。
//  - 设置可覆盖为中文 / English，或跟随系统。
//  - 当前语言缺译时回退 zh-Hans，避免界面显示 key 本身。
//
//  注意：运行时拼接的 key 必须用 `key(_:)`（stringLiteral）。
//  若写成 String.LocalizationValue("a.\(id).b")，会被当成插值模板，Catalog 查不到。
//

import Foundation

enum L10n {
    private static let sourceLanguage = "zh-Hans"

    /// 设置页覆盖：`"zh-Hans"` / `"en"`；`nil` 跟随系统。
    static var languageOverride: String?

    /// 静态 key（`"welcome.appTitle"` 字面量）。
    static func t(_ key: String) -> String {
        resolve(key)
    }

    /// 运行时拼出的语义 key（如 `achievement.\(id).title`）。
    static func key(_ key: String) -> String {
        resolve(key)
    }

    /// `String(format:)`；不用 `locale:`，避免 `%d` 被格式成千分位（与既有单测/中文展示一致）。
    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: resolve(key), arguments: args)
    }

    /// 指定语言查表（单测 / 设置预览）；缺译回退源语言。
    static func t(_ key: String, language: String) -> String {
        let value = string(key, in: language)
        if value != key {
            return value
        }
        return string(key, in: sourceLanguage)
    }

    static func resolvedLanguageCode() -> String {
        if let override = languageOverride, !override.isEmpty {
            return override
        }
        let preferred = Locale.preferredLanguages.first ?? sourceLanguage
        if preferred.hasPrefix("zh") {
            return sourceLanguage
        }
        if preferred.hasPrefix("en") {
            return "en"
        }
        return sourceLanguage
    }

    /// 当前语言优先；缺译时回退 zh-Hans 源文案。
    private static func resolve(_ key: String) -> String {
        t(key, language: resolvedLanguageCode())
    }

    private static func string(_ key: String, in language: String) -> String {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
