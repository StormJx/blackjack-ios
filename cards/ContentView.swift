//
//  ContentView.swift
//  cards
//
//  E1–E4：欢迎双入口、设置/战绩、挑战与快速会话编排。
//

import SwiftUI

/// 进行中的对局会话（牌副 × 玩法）。
private struct ActiveSession: Equatable {
    let practiceMode: PracticeMode
    let playStyle: PlayStyle
}

struct ContentView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var statsStore: StatsStore
    @EnvironmentObject private var propStore: PropStore
    @EnvironmentObject private var challengeProgress: ChallengeProgress
    @EnvironmentObject private var entertainmentProgress: EntertainmentProgress
    @EnvironmentObject private var cosmeticsStore: CosmeticsStore

    @State private var session: ActiveSession?
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var showHelp = false
    /// 破产回主页后的短暂提示；开始新局或超时后清除。
    @State private var welcomeNotice: String?
    @State private var welcomeNoticeClearTask: Task<Void, Never>?
    @State private var didApplyDefaults = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let active = session {
                    TableBackgroundView()
                    GameSessionView(
                        practiceMode: active.practiceMode,
                        playStyle: active.playStyle,
                        cutCardEnabled: active.playStyle == .entertainment
                            ? true
                            : appSettings.cutCardEnabled,
                        statsStore: statsStore,
                        propStore: propStore,
                        challengeProgress: challengeProgress,
                        entertainmentProgress: entertainmentProgress,
                        cosmeticsStore: cosmeticsStore,
                        onEndSession: { showClearedHint in
                            withAnimation(.easeInOut(duration: 0.28)) {
                                session = nil
                            }
                            ActiveTableLimits.apply(appSettings.tableLimitPreset)
                            let leveledUp = challengeProgress.syncFromStats(
                                dealerClears: statsStore.dealerBankClearCount,
                                totalChipsWon: statsStore.totalChipsWon
                            )
                            let newlyBacks = cosmeticsStore.syncFromProgress(
                                unlockedLevel: challengeProgress.unlockedLevel,
                                dealerClears: statsStore.dealerBankClearCount,
                                totalChipsWon: statsStore.totalChipsWon
                            )
                            if showClearedHint {
                                presentWelcomeNotice(ChipRules.sessionClearedReturnHomeHint)
                            } else if leveledUp {
                                presentWelcomeNotice("解锁\(challengeProgress.currentStage.title)")
                            } else if let back = newlyBacks.first {
                                presentWelcomeNotice("卡背解锁：\(back.title)")
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
                } else {
                    WelcomeBackgroundView()
                    welcomeView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.28), value: session != nil)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: appSettings, cosmetics: cosmeticsStore)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showStats) {
                StatsView(stats: statsStore)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView(stats: statsStore, props: propStore)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                guard !didApplyDefaults else { return }
                didApplyDefaults = true
                ActiveTableLimits.apply(appSettings.tableLimitPreset)
                _ = challengeProgress.syncFromStats(
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                )
                _ = cosmeticsStore.syncFromProgress(
                    unlockedLevel: challengeProgress.unlockedLevel,
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                )
                _ = propStore.syncFromAchievements(statsStore.unlockedIDs)
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    GameFeedback.shared.buttonTap()
                    showAchievements = true
                } label: {
                    Label("成就", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    GameFeedback.shared.buttonTap()
                    showStats = true
                } label: {
                    Label("战绩", systemImage: "chart.bar.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Spacer(minLength: 0)

                Button {
                    GameFeedback.shared.buttonTap()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .padding(8)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityLabel("设置")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer(minLength: 24)

            VStack(spacing: 28) {
                Text("二十一点")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                    .accessibilityAddTraits(.isHeader)

                if let welcomeNotice {
                    Text(welcomeNotice)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(spacing: 14) {
                    Button {
                        startSession(style: .challenge)
                    } label: {
                        Text(PlayStyle.challenge.welcomeButtonTitle)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color(red: 0.92, green: 0.78, blue: 0.28))
                    .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.12))

                    Button {
                        startSession(style: .entertainment)
                    } label: {
                        Text(PlayStyle.entertainment.welcomeButtonTitle)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
                }
                .frame(maxWidth: 320)

                Button {
                    GameFeedback.shared.buttonTap()
                    showHelp = true
                } label: {
                    Label("帮助说明", systemImage: "questionmark.circle")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.22), value: welcomeNotice)
    }

    private func startSession(style: PlayStyle) {
        GameFeedback.shared.buttonTap()
        clearWelcomeNotice()
        switch style {
        case .challenge:
            ActiveTableLimits.apply(appSettings.tableLimitPreset)
        case .entertainment:
            let stage = entertainmentProgress.currentStage
            ActiveTableLimits.apply(
                minimumBet: stage.minimumBet,
                betChipValues: stage.betChipValues
            )
        }
        withAnimation(.easeInOut(duration: 0.28)) {
            session = ActiveSession(
                practiceMode: appSettings.defaultPracticeMode,
                playStyle: style
            )
        }
    }

    private func presentWelcomeNotice(_ text: String) {
        welcomeNoticeClearTask?.cancel()
        withAnimation(.easeInOut(duration: 0.22)) {
            welcomeNotice = text
        }
        welcomeNoticeClearTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                clearWelcomeNotice()
            }
        }
    }

    private func clearWelcomeNotice() {
        welcomeNoticeClearTask?.cancel()
        welcomeNoticeClearTask = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            welcomeNotice = nil
        }
    }
}

// MARK: - 对局会话

private struct GameSessionView: View {
    @StateObject private var game: BlackjackGame
    @StateObject private var chipBank: ChipBank
    let practiceMode: PracticeMode
    let playStyle: PlayStyle
    @ObservedObject var statsStore: StatsStore
    @ObservedObject var propStore: PropStore
    @ObservedObject var challengeProgress: ChallengeProgress
    @ObservedObject var entertainmentProgress: EntertainmentProgress
    @ObservedObject var cosmeticsStore: CosmeticsStore
    /// `true`：破产「返回主页」后提示进度已清空；主动退出叉号则为 `false`。
    let onEndSession: (_ showClearedHint: Bool) -> Void

    @State private var didPresentInitialFlow = false
    @State private var showBetSheet = false
    @State private var showRoundEndSheet = false
    @State private var showAbandonConfirm = false
    @State private var controlsLockedAfterAllIn = false
    @State private var draftBet = 0
    /// P3：本会话上一局确认下注额（仅娱乐「同上局」）。
    @State private var lastConfirmedBet = 0
    /// 本会话已完成局数；满 5 局解锁开局全下。
    @State private var sessionRoundsCompleted = 0
    @State private var chipBalancePulse = false
    @State private var achievementToast: String?
    @State private var achievementToastTask: Task<Void, Never>?

    init(
        practiceMode: PracticeMode,
        playStyle: PlayStyle,
        cutCardEnabled: Bool,
        statsStore: StatsStore,
        propStore: PropStore,
        challengeProgress: ChallengeProgress,
        entertainmentProgress: EntertainmentProgress,
        cosmeticsStore: CosmeticsStore,
        onEndSession: @escaping (_ showClearedHint: Bool) -> Void
    ) {
        self.practiceMode = practiceMode
        self.playStyle = playStyle
        self.statsStore = statsStore
        self.propStore = propStore
        self.challengeProgress = challengeProgress
        self.entertainmentProgress = entertainmentProgress
        self.cosmeticsStore = cosmeticsStore
        self.onEndSession = onEndSession
        _game = StateObject(wrappedValue: BlackjackGame(
            practiceMode: practiceMode,
            cutCardEnabled: cutCardEnabled
        ))
        switch playStyle {
        case .challenge:
            let stage = challengeProgress.currentStage
            _chipBank = StateObject(wrappedValue: ChipBank(
                startingBalance: stage.playerStart,
                dealerStartingBank: stage.dealerStart
            ))
        case .entertainment:
            let stage = entertainmentProgress.currentStage
            let suiteName = "cards.chipBank.entertainment"
            let suite = UserDefaults(suiteName: suiteName) ?? .standard
            _chipBank = StateObject(wrappedValue: ChipBank(
                defaults: suite,
                storageKey: "entertainment.balance",
                dealerBankKey: "entertainment.dealerBank",
                activeBetKey: "entertainment.activeBet",
                startingBalance: stage.playerStart,
                dealerStartingBank: stage.dealerStart
            ))
        }
    }

    var body: some View {
        ZStack {
            gameTableView

            if showBetSheet {
                sessionPanelOverlay { betPanelContent }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            if showRoundEndSheet {
                sessionPanelOverlay { roundEndPanelContent }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(3)
            }

            if game.isShowingShuffleScreen {
                ShuffleScreenOverlay(cutCardEnabled: game.cutCardEnabled)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(4)
            }

            VStack {
                HStack {
                    exitToolbarButton
                        .padding(.leading, 34)
                        .padding(.top, 30)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .zIndex(10)
        }
        .animation(.easeInOut(duration: 0.28), value: game.isShowingShuffleScreen)
        .animation(.easeInOut(duration: 0.28), value: showBetSheet)
        .animation(.easeInOut(duration: 0.28), value: showRoundEndSheet)
        .modifier(AbandonConfirmModifier(
            isPresented: $showAbandonConfirm,
            playStyle: playStyle,
            onConfirm: abandonSessionToWelcome
        ))
        .onChange(of: game.phase) { _, newPhase in
            if newPhase != .playerTurn {
                controlsLockedAfterAllIn = false
            }
            if newPhase == .finished {
                handleRoundFinished()
                showRoundEndSheet = true
            } else {
                showRoundEndSheet = false
            }
        }
        .onAppear {
            guard !didPresentInitialFlow else { return }
            didPresentInitialFlow = true
            beginInitialFlow()
        }
    }

    private func beginInitialFlow() {
        if chipBank.isSessionOver {
            showRoundEndSheet = true
        } else {
            prepareBetDraft()
            showBetSheet = true
        }
    }

    private func sessionPanelOverlay<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 88)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(.systemGroupedBackground))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 22,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 22,
                        style: .continuous
                    )
                )
                .shadow(color: .black.opacity(0.12), radius: 16, y: -4)
        }
        .background(Color.black.opacity(0.35).ignoresSafeArea())
    }

    private var betPanelContent: some View {
        SessionBetPanel(
            balance: chipBank.balance,
            draftBet: $draftBet,
            showRestoreHint: chipBank.didRestoreAfterInterrupt,
            canConfirm: canConfirmBet,
            sessionRoundsCompleted: sessionRoundsCompleted,
            emphasizeForcedAllIn: game.isForcedAllInAvailable
                && sessionRoundsCompleted >= ChipRules.preDealAllInUnlockCompletedRounds,
            showsRepeatLastBet: playStyle == .entertainment,
            lastBetAmount: lastConfirmedBet,
            canRepeatLastBet: canRepeatLastBet,
            onClear: clearDraftBet,
            onSelectChip: selectChip,
            onAllIn: applyPreDealAllIn,
            onRepeatLastBet: applyRepeatLastBet,
            onConfirm: confirmBetAndDeal
        )
    }

    private var roundEndPanelContent: some View {
        SessionRoundEndPanel(
            playStyle: playStyle,
            isSessionOver: chipBank.isSessionOver,
            sessionEndReason: chipBank.sessionEndReason,
            outcomeMessage: game.outcomeMessage,
            outcome: game.lastOutcome,
            settlement: chipBank.lastSettlement,
            balance: chipBank.balance,
            dealerBank: chipBank.dealerBank,
            shoeStatusLine: game.shoeStatusLine,
            fastStats: nil,
            achievementToast: achievementToast,
            onReturnHome: returnToWelcomeAfterSessionEnd,
            onContinue: continueAfterRound
        )
    }

    private var gameTableView: some View {
        GameTableView(
            game: game,
            chipBank: chipBank,
            playStyle: playStyle,
            showBetPanel: showBetSheet,
            showRoundEndPanel: showRoundEndSheet,
            canHit: canHit,
            canStand: canStand,
            showsMidHandAllIn: propStore.canUse(.midHandAllIn, in: playStyle),
            canMidHandAllIn: canMidHandAllIn,
            emphasizeForcedAllIn: emphasizeForcedAllIn,
            showsPeekHole: propStore.canUse(.peekHole, in: playStyle),
            canPeekHole: canPeekHole,
            showsSoft17Hit: propStore.canUse(.dealerSoft17Hit, in: playStyle),
            canSoft17Hit: canSoft17Hit,
            soft17HitActive: game.dealerHitsSoft17ThisRound,
            showsRedrawOne: propStore.canUse(.redrawOne, in: playStyle),
            canRedrawOne: canRedrawOne,
            showsReshuffleDealerCard: propStore.canUse(.reshuffleDealerCard, in: playStyle),
            canReshuffleDealerCard: canReshuffleDealerCard,
            chipBalancePulse: chipBalancePulse,
            cardBack: cosmeticsStore.selectedBack,
            onHit: { Task { await game.hit() } },
            onStand: { Task { await game.stand() } },
            onAllIn: performMidHandAllIn,
            onPeekHole: { Task { await game.peekHoleCard() } },
            onSoft17Hit: { _ = game.activateDealerSoft17Hit() },
            onRedrawOne: { Task { await game.redrawLastHitCard() } },
            onReshuffleDealerCard: { Task { _ = await game.reshuffleDealerCard() } }
        )
    }

    private var exitToolbarButton: some View {
        Button {
            GameFeedback.shared.buttonTap()
            showAbandonConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.primary.opacity(0.85), Color.primary.opacity(0.12))
                .padding(4)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("退出本局")
    }

    private var canConfirmBet: Bool {
        draftBet >= ChipRules.minimumBet
            && draftBet <= chipBank.balance
            && chipBank.activeBet == 0
            && !chipBank.isSessionOver
            && !game.isAnimating
    }

    private var canHit: Bool {
        game.phase == .playerTurn && !game.isAnimating && !controlsLockedAfterAllIn
    }

    private var canStand: Bool {
        game.phase == .playerTurn && !game.isAnimating && !controlsLockedAfterAllIn
    }

    private var canMidHandAllIn: Bool {
        propStore.canUse(.midHandAllIn, in: playStyle)
            && game.phase == .playerTurn
            && !game.isAnimating
            && !controlsLockedAfterAllIn
            && chipBank.activeBet > 0
            && chipBank.balance > 0
    }

    private var emphasizeForcedAllIn: Bool {
        canMidHandAllIn && game.isForcedAllInAvailable
    }

    private var canPeekHole: Bool {
        propStore.canUse(.peekHole, in: playStyle) && game.canPeekHoleCard && !controlsLockedAfterAllIn
    }

    private var canSoft17Hit: Bool {
        propStore.canUse(.dealerSoft17Hit, in: playStyle)
            && game.canActivateDealerSoft17Hit
            && !controlsLockedAfterAllIn
    }

    private var canRedrawOne: Bool {
        propStore.canUse(.redrawOne, in: playStyle)
            && game.canRedrawLastHitCard
            && !controlsLockedAfterAllIn
    }

    private var canReshuffleDealerCard: Bool {
        propStore.canUse(.reshuffleDealerCard, in: playStyle)
            && game.canReshuffleDealerCard
            && !controlsLockedAfterAllIn
    }

    private var canRepeatLastBet: Bool {
        playStyle == .entertainment
            && lastConfirmedBet >= ChipRules.minimumBet
            && lastConfirmedBet <= chipBank.balance
            && chipBank.activeBet == 0
            && !chipBank.isSessionOver
    }

    private func prepareBetDraft() {
        draftBet = 0
    }

    private func clearDraftBet() {
        draftBet = 0
    }

    /// 三档单选：点选即覆盖为该档注码。
    private func selectChip(_ value: Int) {
        guard ChipRules.canSelectBetChip(value, balance: chipBank.balance) else { return }
        draftBet = value
    }

    private func applyRepeatLastBet() {
        guard canRepeatLastBet else { return }
        draftBet = lastConfirmedBet
    }

    /// 开局全下：须已解锁且当前未选筹码档。
    private func applyPreDealAllIn() {
        guard ChipRules.isPreDealAllInEnabled(
            balance: chipBank.balance,
            sessionRoundsCompleted: sessionRoundsCompleted,
            draftBet: draftBet
        ) else { return }
        draftBet = chipBank.balance
    }

    private func performMidHandAllIn() {
        guard canMidHandAllIn else { return }
        controlsLockedAfterAllIn = true
        guard chipBank.goAllIn() != nil else {
            controlsLockedAfterAllIn = false
            return
        }
        Task { await game.stand() }
    }

    private func confirmBetAndDeal() {
        guard chipBank.placeBet(draftBet) else { return }
        if playStyle == .entertainment {
            lastConfirmedBet = draftBet
        }
        chipBank.acknowledgeRestoreHint()
        GameFeedback.shared.betPlaced()
        pulseChipBalance()
        showBetSheet = false
        Task { await game.startNewRound() }
    }

    private func pulseChipBalance() {
        chipBalancePulse = true
        Task {
            try? await Task.sleep(nanoseconds: 420_000_000)
            await MainActor.run { chipBalancePulse = false }
        }
    }

    private func handleRoundFinished() {
        settleCurrentRoundIfNeeded()
        if let outcome = game.lastOutcome {
            sessionRoundsCompleted += 1
            if let snapshot = game.makeRoundSnapshot(
                wasAllInBet: chipBank.activeBetWasAllIn
            ) {
                let scope = playStyle.achievementScope
                let newly = statsStore.recordRound(snapshot: snapshot, scope: scope)
                var toastTitles = newly.map(\.title)
                if playStyle == .challenge, chipBank.sessionEndReason == .dealerBroke {
                    let beforePending = statsStore.pendingUnlockTitles
                    statsStore.recordDealerBankCleared()
                    let afterPending = statsStore.pendingUnlockTitles
                    let extra = afterPending.dropFirst(beforePending.count)
                    toastTitles.append(contentsOf: extra)
                    if challengeProgress.syncFromStats(
                        dealerClears: statsStore.dealerBankClearCount,
                        totalChipsWon: statsStore.totalChipsWon
                    ) {
                        toastTitles.append("闯关·\(challengeProgress.currentStage.title)")
                    }
                }
                if playStyle == .entertainment, chipBank.sessionEndReason == .dealerBroke {
                    if entertainmentProgress.recordDealerCleared() {
                        toastTitles.append(entertainmentProgress.currentStage.title)
                    } else {
                        toastTitles.append("娱乐·打穿庄家")
                    }
                }
                let newlyProps = propStore.syncFromAchievements(statsStore.unlockedIDs)
                let newlyBacks = cosmeticsStore.syncFromProgress(
                    unlockedLevel: challengeProgress.unlockedLevel,
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                )
                if playStyle == .entertainment {
                    toastTitles.append(contentsOf: newlyProps.map { "道具·\($0.title)" })
                } else if !newlyProps.isEmpty {
                    toastTitles.append("道具已解锁（娱乐模式可用）")
                }
                toastTitles.append(contentsOf: newlyBacks.map { "卡背·\($0.title)" })
                if !toastTitles.isEmpty {
                    presentAchievementToast(toastTitles.joined(separator: " · "))
                }
            } else if playStyle == .challenge, chipBank.sessionEndReason == .dealerBroke {
                statsStore.recordDealerBankCleared()
                _ = propStore.syncFromAchievements(statsStore.unlockedIDs)
                if challengeProgress.syncFromStats(
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                ) {
                    presentAchievementToast("闯关·\(challengeProgress.currentStage.title)")
                }
                _ = cosmeticsStore.syncFromProgress(
                    unlockedLevel: challengeProgress.unlockedLevel,
                    dealerClears: statsStore.dealerBankClearCount,
                    totalChipsWon: statsStore.totalChipsWon
                )
            } else if playStyle == .entertainment, chipBank.sessionEndReason == .dealerBroke {
                if entertainmentProgress.recordDealerCleared() {
                    presentAchievementToast(entertainmentProgress.currentStage.title)
                }
            }
        } else if chipBank.activeBet > 0 {
            chipBank.refundActiveBet()
        }
    }

    private func settleCurrentRoundIfNeeded() {
        if let outcome = game.lastOutcome {
            if let result = chipBank.settle(outcome: outcome) {
                if playStyle == .challenge {
                    statsStore.recordChipSettlement(netChange: result.netChange)
                    _ = challengeProgress.syncFromStats(
                        dealerClears: statsStore.dealerBankClearCount,
                        totalChipsWon: statsStore.totalChipsWon
                    )
                    _ = cosmeticsStore.syncFromProgress(
                        unlockedLevel: challengeProgress.unlockedLevel,
                        dealerClears: statsStore.dealerBankClearCount,
                        totalChipsWon: statsStore.totalChipsWon
                    )
                } else if playStyle == .entertainment {
                    entertainmentProgress.recordChipsWon(result.netChange)
                }
                pulseChipBalance()
            }
        } else if chipBank.activeBet > 0 {
            chipBank.refundActiveBet()
        }
    }

    private func continueAfterRound() {
        showRoundEndSheet = false
        achievementToast = nil
        prepareBetDraft()
        showBetSheet = true
    }

    private func presentAchievementToast(_ text: String) {
        achievementToastTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            achievementToast = "成就解锁：\(text)"
        }
        achievementToastTask = Task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    achievementToast = nil
                }
            }
        }
    }

    private func returnToWelcomeAfterSessionEnd() {
        showBetSheet = false
        showRoundEndSheet = false
        chipBank.acknowledgeRestoreHint()
        chipBank.abandonSession()
        onEndSession(true)
    }

    private func abandonSessionToWelcome() {
        showBetSheet = false
        showRoundEndSheet = false
        chipBank.refundActiveBet()
        chipBank.acknowledgeRestoreHint()
        chipBank.abandonSession()
        onEndSession(false)
    }
}

// MARK: - 退出确认

private struct AbandonConfirmModifier: ViewModifier {
    @Binding var isPresented: Bool
    let playStyle: PlayStyle
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "退出本局？",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button(playStyle.abandonConfirmButtonTitle, role: .destructive) {
                    onConfirm()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(playStyle.abandonConfirmDetail)
            }
    }
}

// MARK: - 局间洗牌全屏页

private struct ShuffleScreenOverlay: View {
    let cutCardEnabled: Bool
    @State private var pulse = false
    @State private var fan = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.12, green: 0.28, blue: 0.48),
                                        Color(red: 0.08, green: 0.18, blue: 0.34),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 104)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                            )
                            .rotationEffect(.degrees(fan ? Double(i - 2) * 14 : 0))
                            .offset(x: fan ? CGFloat(i - 2) * 10 : 0)
                            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    }
                }
                .scaleEffect(pulse ? 1.06 : 0.96)
                .animation(
                    .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                    value: pulse
                )
                .animation(
                    .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                    value: fan
                )

                VStack(spacing: 8) {
                    Text("洗牌中…")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(cutCardEnabled
                         ? "切牌点已过，正在重新整理牌堆"
                         : "本局已结束，正在重新整理牌堆")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("洗牌中")
        .onAppear {
            pulse = true
            fan = true
        }
    }
}

// MARK: - 欢迎页背景（牌桌绿）

private struct WelcomeBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            // 主色：赌场绒布绿（深色模式下略压暗）
            Color(
                red: isDark ? 0.08 : 0.12,
                green: isDark ? 0.28 : 0.42,
                blue: isDark ? 0.18 : 0.28
            )
            // 轻微微光，避免死板平涂
            RadialGradient(
                colors: [
                    Color.white.opacity(isDark ? 0.06 : 0.10),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 20,
                endRadius: 420
            )
            // 底部略暗，托住主按钮区
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(isDark ? 0.28 : 0.18),
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - 牌桌背景

private struct TableBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            LinearGradient(
                colors: isDark
                    ? [
                        Color(red: 0.10, green: 0.12, blue: 0.16),
                        Color(red: 0.06, green: 0.08, blue: 0.11),
                    ]
                    : [
                        Color(red: 0.94, green: 0.95, blue: 0.97),
                        Color(red: 0.86, green: 0.88, blue: 0.93),
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    (isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.55)),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.15, y: 0.1),
                startRadius: 40,
                endRadius: 520
            )
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(isDark ? 0.28 : 0.04),
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(StatsStore())
        .environmentObject(PropStore())
        .environmentObject(ChallengeProgress())
        .environmentObject(EntertainmentProgress())
        .environmentObject(CosmeticsStore())
}
