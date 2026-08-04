//
//  L10n.swift
//  cards
//
//  L1：本地化入口。文案在 Localizable.xcstrings（源语言 zh-Hans）。
//  - 语义化 key（如 welcome.appTitle），便于后续只改 Catalog 补英文。
//  - 欢迎页相关 key 已提供 en；其余暂仅 zh-Hans，系统英文本地会回退中文。
//  - 扩英文：在 Xcode String Catalog 或 xcstrings 里为对应 key 增加 "en" 即可。
//
//  注意：运行时拼接的 key 必须用 `key(_:)`（stringLiteral）。
//  若写成 String.LocalizationValue("a.\(id).b")，会被当成插值模板，Catalog 查不到。
//

import Foundation

enum L10n {
    /// 静态 key（`"welcome.appTitle"` 字面量）。
    static func t(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }

    /// 运行时拼出的语义 key（如 `achievement.\(id).title`）。
    static func key(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key))
    }

    /// `String(format:)`；不用 `locale:`，避免 `%d` 被格式成千分位（与既有单测/中文展示一致）。
    static func format(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        String(format: String(localized: key), arguments: args)
    }
}
