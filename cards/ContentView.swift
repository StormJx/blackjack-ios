//
//  ContentView.swift
//  cards
//

import SwiftUI

struct ContentView: View {
    @State private var session: PracticeMode?
    @State private var selectedMode: PracticeMode = .singleDeck
    /// 破产回主页后的短暂提示；开始新局或超时后清除。
    @State private var welcomeNotice: String?
    @State private var welcomeNoticeClearTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackgroundView()
                if let mode = session {
                    GameSessionView(practiceMode: mode, onEndSession: { showClearedHint in
                        withAnimation(.easeInOut(duration: 0.28)) {
                            session = nil
                        }
                        if showClearedHint {
                            presentWelcomeNotice(ChipRules.sessionClearedReturnHomeHint)
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
                } else {
                    welcomeView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.28), value: session != nil)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var welcomeView: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Text("二十一点")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("练习模式")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(ChipRules.welcomeRulesSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let welcomeNotice {
                    Text(welcomeNotice)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("牌副")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("牌副", selection: $selectedMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Text(mode.pickerLabel).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)

                HStack(spacing: 8) {
                    welcomeTag(selectedMode.shortLabel)
                    welcomeTag("你 \(ChipRules.startingBalance)")
                    welcomeTag("庄家 \(ChipRules.dealerStartingBank)")
                }
                .padding(.top, 2)

                Button("开始游戏") {
                    GameFeedback.shared.buttonTap()
                    clearWelcomeNotice()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        session = selectedMode
                    }
                    // GameSessionView 会在 onAppear 中开局；见 GameSessionView
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .animation(.easeInOut(duration: 0.22), value: welcomeNotice)
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

    private func welcomeTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }
}

// MARK: - 对局会话（按 PracticeMode 绑定 Game，避免 StateObject 与模式不一致）

private struct GameSessionView: View {
    @StateObject private var game: BlackjackGame
    @StateObject private var chipBank = ChipBank()
    let practiceMode: PracticeMode
    /// `true`：破产「返回主页」后提示进度已清空；主动退出叉号则为 `false`。
    let onEndSession: (_ showClearedHint: Bool) -> Void
    @State private var didPresentInitialBet = false
    @State private var showBetSheet = false
    @State private var showRoundEndSheet = false
    @State private var showAbandonConfirm = false
    /// 全下已提交、stand 动画尚未把 isAnimating 置 true 时，锁住底部键防连点。
    @State private var controlsLockedAfterAllIn = false
    /// 草稿注码：从 0 累加筹码；确认时须 ≥ 最小下注。
    @State private var draftBet = 0

    init(practiceMode: PracticeMode, onEndSession: @escaping (_ showClearedHint: Bool) -> Void) {
        self.practiceMode = practiceMode
        self.onEndSession = onEndSession
        _game = StateObject(wrappedValue: BlackjackGame(practiceMode: practiceMode))
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
                ShuffleScreenOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(4)
            }

            // 全会话唯一退出入口：始终在界面左上角；下注/结果面板不再放叉号。
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
            onConfirm: abandonSessionToWelcome
        ))
        .onChange(of: game.phase) { _, newPhase in
            if newPhase != .playerTurn {
                controlsLockedAfterAllIn = false
            }
            if newPhase == .finished {
                settleCurrentRoundIfNeeded()
                showRoundEndSheet = true
            } else {
                showRoundEndSheet = false
            }
        }
        .onAppear {
            guard !didPresentInitialBet else { return }
            didPresentInitialBet = true
            if chipBank.isSessionOver {
                // 杀进程后若会话已因破产结束，直接进入最终结果，避免再打开下注页。
                showRoundEndSheet = true
            } else {
                prepareBetDraft()
                showBetSheet = true
            }
        }
    }

    /// 底部面板：留出顶部给牌桌标题与唯一退出叉号。
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
            emphasizeForcedAllIn: game.isForcedAllInAvailable,
            onClear: clearDraftBet,
            onAddChip: addChip,
            onAddRemaining: addRemainingBalance,
            onAllIn: applyPreDealAllIn,
            onConfirm: confirmBetAndDeal
        )
    }

    private var roundEndPanelContent: some View {
        SessionRoundEndPanel(
            isSessionOver: chipBank.isSessionOver,
            sessionEndReason: chipBank.sessionEndReason,
            outcomeMessage: game.outcomeMessage,
            outcome: game.lastOutcome,
            settlement: chipBank.lastSettlement,
            balance: chipBank.balance,
            dealerBank: chipBank.dealerBank,
            shoeStatusLine: game.shoeStatusLine,
            onReturnHome: returnToWelcomeAfterSessionEnd,
            onContinue: {
                showRoundEndSheet = false
                prepareBetDraft()
                showBetSheet = true
            }
        )
    }

    private var gameTableView: some View {
        GameTableView(
            game: game,
            chipBank: chipBank,
            showBetPanel: showBetSheet,
            showRoundEndPanel: showRoundEndSheet,
            canHit: canHit,
            canStand: canStand,
            showsMidHandAllIn: ChipRules.midHandAllInEnabled,
            canMidHandAllIn: canMidHandAllIn,
            emphasizeForcedAllIn: emphasizeForcedAllIn,
            onHit: { Task { await game.hit() } },
            onStand: { Task { await game.stand() } },
            onAllIn: performMidHandAllIn
        )
    }

    /// 全会话唯一退出入口（牌桌左上角；先确认，防误触）。
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

    /// 道具预留：见牌后再全下（默认 `midHandAllInEnabled == false` 时 UI 不展示）。
    private var canMidHandAllIn: Bool {
        ChipRules.midHandAllInEnabled
            && game.phase == .playerTurn
            && !game.isAnimating
            && !controlsLockedAfterAllIn
            && chipBank.activeBet > 0
            && chipBank.balance > 0
    }

    /// 道具预留：一副牌残局时对局中全下的强调样式。
    private var emphasizeForcedAllIn: Bool {
        canMidHandAllIn && game.isForcedAllInAvailable
    }

    /// 每局重新从 0 累加，避免「草稿已含旧注 + 再点 200」误判为余额不足。
    private func prepareBetDraft() {
        draftBet = 0
    }

    private func clearDraftBet() {
        draftBet = 0
    }

    private func addChip(_ value: Int) {
        guard value > 0, draftBet + value <= chipBank.balance else { return }
        draftBet += value
    }

    private func addRemainingBalance() {
        let amount = ChipRules.remainingDraftAddAmount(draftBet: draftBet, balance: chipBank.balance)
        guard amount > 0 else { return }
        draftBet += amount
    }

    /// 开局全下：草稿注码设为全部余额，再由「确认并发牌」落注。
    private func applyPreDealAllIn() {
        guard ChipRules.canPreDealAllIn(balance: chipBank.balance) else { return }
        draftBet = chipBank.balance
    }

    /// 道具预留：见牌后全下并自动停牌（`ChipBank.goAllIn`）。
    private func performMidHandAllIn() {
        guard canMidHandAllIn else { return }
        // 先于 goAllIn / stand 上锁，避免 isAnimating 尚未置位时要牌/停牌仍可点。
        controlsLockedAfterAllIn = true
        guard chipBank.goAllIn() != nil else {
            controlsLockedAfterAllIn = false
            return
        }
        // 全下后本局注码已定，自动停牌进入庄家回合。
        Task { await game.stand() }
    }

    private func confirmBetAndDeal() {
        guard chipBank.placeBet(draftBet) else { return }
        chipBank.acknowledgeRestoreHint()
        showBetSheet = false
        Task { await game.startNewRound() }
    }

    private func settleCurrentRoundIfNeeded() {
        if let outcome = game.lastOutcome {
            _ = chipBank.settle(outcome: outcome)
        } else if chipBank.activeBet > 0 {
            // 发牌异常等未产生胜负时退注，避免重复扣款。
            chipBank.refundActiveBet()
        }
    }

    /// 破产会话结束：清空筹码并回欢迎页；新一局须从主页再次「开始游戏」。
    private func returnToWelcomeAfterSessionEnd() {
        showBetSheet = false
        showRoundEndSheet = false
        chipBank.acknowledgeRestoreHint()
        chipBank.abandonSession()
        onEndSession(true)
    }

    /// 放弃整局：退未结算注、清空会话筹码、返回欢迎页（不计入历史；与杀进程恢复相对）。
    private func abandonSessionToWelcome() {
        showBetSheet = false
        showRoundEndSheet = false
        chipBank.refundActiveBet()
        chipBank.acknowledgeRestoreHint()
        chipBank.abandonSession()
        onEndSession(false)
    }
}

// MARK: - 退出确认（牌桌与 sheet 共用，避免 sheet 盖住时无法弹确认）

private struct AbandonConfirmModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "退出本局？",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("退出并清空筹码", role: .destructive) {
                    onConfirm()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(ChipRules.abandonSessionConfirmDetail)
            }
    }
}

// MARK: - 局间洗牌全屏页

private struct ShuffleScreenOverlay: View {
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
                    Text("切牌点已过，正在重新整理牌堆")
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

// MARK: - 牌桌背景（中性冷灰渐变 + 柔光）

private struct TableBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.95, blue: 0.97),
                    Color(red: 0.86, green: 0.88, blue: 0.93),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.15, y: 0.1),
                startRadius: 40,
                endRadius: 520
            )
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.04),
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
}
