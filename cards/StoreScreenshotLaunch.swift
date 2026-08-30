//
//  StoreScreenshotLaunch.swift
//  cards
//
//  L5：仅商店截图脚本使用。正式包不会带这些启动参数。
//

import Foundation

enum StoreScreenshotLaunch {
    /// `-StoreLanguage zh-Hans` 或 `en`，写入设置后再建 Store，避免跟系统语言。
    static var languageRaw: String? {
        argumentValue("-StoreLanguage")
    }

    /// `-StoreScreenshot <scene>`，scene 为 welcome / settings / privacy / help / achievements / stats / bet / table。
    static var scene: String? {
        argumentValue("-StoreScreenshot")
    }

    private static func argumentValue(_ flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        let value = arguments[index + 1]
        return value.hasPrefix("-") ? nil : value
    }
}
