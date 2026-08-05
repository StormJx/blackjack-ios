//
//  L10n.swift
//  cards
//
//  L1：本地化入口。文案在 Localizable.xcstrings（源语言 zh-Hans）。
//  - 语义化 key（如 welcome.appTitle），便于后续只改 Catalog 补英文。
//  - 欢迎页相关 key 已提供 en；其余暂仅 zh-Hans。
//  - 扩英文：在 Xcode String Catalog 或 xcstrings 里为对应 key 增加 "en" 即可。
//
//  回退约定：当前语言（如 en）若缺某 key，Foundation 会返回 key 本身
//  （因为 en.lproj 存在但不完整）。此时显式回退到 zh-Hans 源文案，
//  避免界面/CI 英文本地显示「practice.deck.single」这类 key。
//
//  注意：运行时拼接的 key 必须用 `key(_:)`（stringLiteral）。
//  若写成 String.LocalizationValue("a.\(id).b")，会被当成插值模板，Catalog 查不到。
//

import Foundation

enum L10n {
    private static let sourceLanguage = "zh-Hans"

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

    /// 指定语言查表（单测用；正式 UI 走 `t` / `key` 的自动回退）。
    static func t(_ key: String, language: String) -> String {
        string(key, in: language)
    }

    /// 当前语言优先；缺译时回退 zh-Hans 源文案。
    private static func resolve(_ key: String) -> String {
        let preferred = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        if preferred != key {
            return preferred
        }
        return string(key, in: sourceLanguage)
    }

    private static func string(_ key: String, in language: String) -> String {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
