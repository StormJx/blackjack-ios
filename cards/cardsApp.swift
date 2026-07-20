//
//  cardsApp.swift
//  cards
//
//  Created by 姬翔 on 2026/4/4.
//

import SwiftUI

@main
struct cardsApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var statsStore = StatsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(statsStore)
        }
    }
}
