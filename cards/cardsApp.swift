//
//  cardsApp.swift
//  cards
//
//  Created by 姬翔 on 2026/4/4.
//

import SwiftUI

@main
struct cardsApp: App {
    @StateObject private var appSettings: AppSettings
    @StateObject private var statsStore: StatsStore
    @StateObject private var propStore: PropStore
    @StateObject private var challengeProgress: ChallengeProgress
    @StateObject private var entertainmentProgress: EntertainmentProgress
    @StateObject private var cosmeticsStore: CosmeticsStore

    init() {
        // A2：须在各 Store 读 UserDefaults 之前完成 schema 迁移。
        DataSchema.migrateIfNeeded()
        _appSettings = StateObject(wrappedValue: AppSettings())
        _statsStore = StateObject(wrappedValue: StatsStore())
        _propStore = StateObject(wrappedValue: PropStore())
        _challengeProgress = StateObject(wrappedValue: ChallengeProgress())
        _entertainmentProgress = StateObject(wrappedValue: EntertainmentProgress())
        _cosmeticsStore = StateObject(wrappedValue: CosmeticsStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(statsStore)
                .environmentObject(propStore)
                .environmentObject(challengeProgress)
                .environmentObject(entertainmentProgress)
                .environmentObject(cosmeticsStore)
                .onAppear {
                    _ = challengeProgress.syncFromStats(
                        dealerClears: statsStore.dealerBankClearCount,
                        totalChipsWon: statsStore.totalChipsWon
                    )
                }
        }
    }
}
