//
//  TableWallpaperTests.swift
//  cardsTests
//
//  背景场景：未知值回绿绒，图片场景各有独立资源名。
//

import Foundation
import Testing
@testable import cards

struct TableWallpaperTests {

    @Test func unknownStoredValueFallsBackToClassicFelt() {
        #expect(TableWallpaper.resolved(nil) == .classicFelt)
        #expect(TableWallpaper.resolved("missing-scene") == .classicFelt)
        #expect(TableWallpaper.resolved(TableWallpaper.harborDusk.rawValue) == .harborDusk)
    }

    @Test func imageScenesUseDistinctAssetNames() {
        let names = TableWallpaper.allCases.compactMap(\.assetName)
        #expect(names.count == 4)
        #expect(Set(names).count == names.count)
        #expect(TableWallpaper.classicFelt.assetName == nil)
        #expect(TableWallpaper.nightCasino.assetName == "wallpaper-night-casino")
    }
}
