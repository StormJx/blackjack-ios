//
//  TableWallpaper.swift
//  cards
//
//  欢迎页与对局共用的背景场景。
//
//  换图：覆盖 `Assets.xcassets/Wallpapers/<imageset>/` 里的同名图片。
//  新场景：加一个 case、一张 imageset、一条 `wallpaper.<rawValue>.title`。
//  供图像素和格式写在仓库根目录 `wallpaper-brief/`，该目录不入库。
//

import Foundation
import SwiftUI
import UIKit

enum TableWallpaper: String, CaseIterable, Identifiable, Sendable {
    /// 内置绿绒，不依赖图片。
    case classicFelt
    case nightCasino
    case mahoganySalon
    case harborDusk
    case lanternRoom

    var id: String { rawValue }

    /// 资源目录里的图片名。`nil` 表示用内置绿绒。
    var assetName: String? {
        switch self {
        case .classicFelt:
            return nil
        case .nightCasino:
            return "wallpaper-night-casino"
        case .mahoganySalon:
            return "wallpaper-mahogany"
        case .harborDusk:
            return "wallpaper-harbor"
        case .lanternRoom:
            return "wallpaper-lantern"
        }
    }

    var title: String {
        L10n.key("wallpaper.\(rawValue).title")
    }

    /// 资源缺失时背景回到绿绒，设置缩略图也用色块。
    var imageIsAvailable: Bool {
        guard let assetName else { return false }
        return UIImage(named: assetName) != nil
    }

    /// 未知存档值回到绿绒，避免换图失败时黑屏。
    static func resolved(_ raw: String?) -> TableWallpaper {
        guard let raw, let wallpaper = TableWallpaper(rawValue: raw) else {
            return .classicFelt
        }
        return wallpaper
    }
}
