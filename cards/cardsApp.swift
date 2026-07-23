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
    @StateObject private var propStore = PropStore()
    @StateObject private var challengeProgress = ChallengeProgress()
    @StateObject private var entertainmentProgress = EntertainmentProgress()
    @StateObject private var cosmeticsStore = CosmeticsStore()

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
