//
//  ContentView.swift
//  cards
//

import SwiftUI

struct ContentView: View {
    @State private var session: PracticeMode?
    @State private var selectedMode: PracticeMode = .singleDeck

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackgroundView()
                if let mode = session {
                    GameSessionView(practiceMode: mode, onEndSession: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            session = nil
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
                Text("选择几副牌后进入对局；挑战庄家筹码池，打光或破产即本局结束。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

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
    let onEndSession: () -> Void
    @State private var didPresentInitialBet = false
    @State private var showBetSheet = false
    @State private var showRoundEndSheet = false
    @State private var showAbandonConfirm = false
    /// 草稿注码：从 0 累加筹码；确认时须 ≥ 最小下注。
    @State private var draftBet = 0

    init(practiceMode: PracticeMode, onEndSession: @escaping () -> Void) {
        self.practiceMode = practiceMode
        self.onEndSession = onEndSession
        _game = StateObject(wrappedValue: BlackjackGame(practiceMode: practiceMode))
    }

    var body: some View {
        ZStack {
            gameTableView
            if game.isShowingShuffleScreen {
                ZStack(alignment: .topLeading) {
                    ShuffleScreenOverlay()
                    exitToolbarButton
                        .padding(.leading, 20)
                        .padding(.top, 16)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: game.isShowingShuffleScreen)
        .modifier(AbandonConfirmModifier(
            isPresented: $showAbandonConfirm,
            onConfirm: abandonSessionToWelcome
        ))
        .sheet(isPresented: $showBetSheet) {
            betSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showRoundEndSheet) {
            roundEndSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .onChange(of: game.phase) { _, newPhase in
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

    /// 开局前下注；All In 不在此页（见牌后在对局操作区）。
    private var betSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("下注")
                        .font(.title2.weight(.semibold))
                    Text(draftBet == 0
                         ? "余额 \(chipBank.balance)"
                         : "余额 \(chipBank.balance) · 注 \(draftBet)")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    ForEach(ChipRules.betChipValues, id: \.self) { value in
                        Button {
                            GameFeedback.shared.buttonTap()
                            addChip(value)
                        } label: {
                            Text("+\(value)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canAddChip(value))
                    }
                }

                Button("清空") {
                    GameFeedback.shared.buttonTap()
                    clearDraftBet()
                }
                .font(.subheadline.weight(.semibold))
                .disabled(draftBet == 0)

                Spacer(minLength: 8)

                Button {
                    GameFeedback.shared.buttonTap()
                    confirmBetAndDeal()
                } label: {
                    Text("确认并发牌")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
                .disabled(!canConfirmBet)
                .opacity(canConfirmBet ? 1 : 0.55)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    exitToolbarButton
                }
            }
            .modifier(AbandonConfirmModifier(
                isPresented: $showAbandonConfirm,
                onConfirm: abandonSessionToWelcome
            ))
        }
    }

    /// 本局结束弹窗；若会话因破产结束则切换为最终结果 +「开新游戏」。
    private var roundEndSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text(chipBank.isSessionOver ? "本局游戏结束" : "本局结束")
                        .font(.title2.weight(.semibold))
                    if let reason = chipBank.sessionEndReason {
                        Text(reason.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(reason == .dealerBroke ? .green : .red)
                        Text(reason.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Text(game.outcomeMessage)
                        .font(chipBank.isSessionOver ? .body.weight(.semibold) : .title3.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                VStack(spacing: 8) {
                    if let settlement = chipBank.lastSettlement {
                        Text("本局盈亏 \(settlement.netChangeLabel)")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(settlementNetColor(settlement.netChange))
                        if let odds = settlement.oddsLabel {
                            Text(odds)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        if let partial = settlement.partialPayoutLabel {
                            Text(partial)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                        }
                        Text("你 \(settlement.balanceAfter) · 庄家 \(settlement.dealerBankAfter)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else {
                        Text("你 \(chipBank.balance) · 庄家 \(chipBank.dealerBank)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Text(game.shoeStatusLine)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                .padding(.top, 16)

                Spacer(minLength: 24)

                if chipBank.isSessionOver {
                    Button {
                        GameFeedback.shared.buttonTap()
                        startFreshSessionOnTable()
                    } label: {
                        Text("开新游戏")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                } else {
                    Button {
                        GameFeedback.shared.buttonTap()
                        showRoundEndSheet = false
                        prepareBetDraft()
                        showBetSheet = true
                    } label: {
                        Text("继续")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    exitToolbarButton
                }
            }
            .modifier(AbandonConfirmModifier(
                isPresented: $showAbandonConfirm,
                onConfirm: abandonSessionToWelcome
            ))
        }
    }

    /// 弹窗与牌桌共用的退出入口（先确认，防误触）。
    private var exitToolbarButton: some View {
        Button {
            GameFeedback.shared.buttonTap()
            showAbandonConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("退出本局")
    }

    private var canConfirmBet: Bool {
        draftBet >= ChipRules.minimumBet
            && draftBet <= chipBank.balance
            && chipBank.activeBet == 0
            && !chipBank.isSessionOver
            && !game.isAnimating
    }

    /// 从当前草稿累加该面额后仍不超过余额。
    private func canAddChip(_ value: Int) -> Bool {
        value > 0 && draftBet + value <= chipBank.balance
    }

    /// 玩家回合见牌后：尚有剩余余额时可 All In 追加进本局注。
    private var canMidHandAllIn: Bool {
        game.phase == .playerTurn
            && !game.isAnimating
            && chipBank.activeBet > 0
            && chipBank.balance > 0
    }

    /// 一副牌残局时用强调样式提示 All In。
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
        guard canAddChip(value) else { return }
        draftBet += value
    }

    private func performMidHandAllIn() {
        guard canMidHandAllIn else { return }
        guard chipBank.goAllIn() != nil else { return }
        // 全下后本局注码已定，自动停牌进入庄家回合。
        Task { await game.stand() }
    }

    private func confirmBetAndDeal() {
        guard chipBank.placeBet(draftBet) else { return }
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

    /// 会话结束后留在同副牌模式桌内重置双方筹码，并进入下注。
    private func startFreshSessionOnTable() {
        showRoundEndSheet = false
        chipBank.resetSession()
        prepareBetDraft()
        showBetSheet = true
    }

    /// 放弃整局：退未结算注、清空会话筹码、返回欢迎页（不计入历史）。
    private func abandonSessionToWelcome() {
        showBetSheet = false
        showRoundEndSheet = false
        chipBank.refundActiveBet()
        chipBank.abandonSession()
        onEndSession()
    }

    private func settlementNetColor(_ net: Int) -> Color {
        if net > 0 { return .green }
        if net < 0 { return .red }
        return .orange
    }

    /// 牌面与状态区可滚动；底部仅保留要牌 / 停牌。新一局在本局结束弹窗内操作。
    private var gameTableView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    tableTitle
                    if game.phase == .idle && game.playerCards.isEmpty && !showBetSheet {
                        Text("确认下注后发牌；使用「要牌」「停牌」进行游戏。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    VStack(spacing: 14) {
                        dealerSection
                        playerSection
                        statusSection
                    }
                    .opacity(game.handAreaOpacity)
                    .scaleEffect(game.handAreaScale, anchor: .center)
                    .animation(.easeInOut(duration: 0.35), value: game.handAreaOpacity)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                Divider()
                    .opacity(0.35)
                controls
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var tableTitle: some View {
        HStack(alignment: .center, spacing: 10) {
            exitToolbarButton
                .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("二十一点")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Text(game.shoeStatusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                HStack(spacing: 8) {
                    Text("你 \(chipBank.balance)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    Text("庄家 \(chipBank.dealerBank)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    if chipBank.activeBet > 0 {
                        Text("注 \(chipBank.activeBet)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(game.practiceMode.shortLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
        }
        .padding(.horizontal, 2)
    }

    private var dealerSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("庄家")
                        .font(.title3.weight(.semibold))
                    Spacer(minLength: 0)
                    Text("筹码 \(chipBank.dealerBank)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                LazyVGrid(columns: cardGridColumns, alignment: .leading, spacing: 8) {
                    ForEach(0..<dealerCardFaces.count, id: \.self) { i in
                        PlayingCardView(face: dealerCardFaces[i])
                            .id("\(game.roundToken)-d-\(i)")
                            .cardDealEntrance()
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: dealerCardFaces.count)
                .animation(.easeInOut(duration: 0.32), value: game.dealerHoleRevealed)
                if !game.hideDealerHoleCard || game.phase == .idle {
                    Text("点数：\(visibleDealerValueText())")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary.opacity(0.78))
                } else {
                    Text("明牌点数：\(dealerUpcardValueText())")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary.opacity(0.78))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playerSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("玩家")
                        .font(.title3.weight(.semibold))
                    Spacer(minLength: 0)
                    Text("筹码 \(chipBank.balance)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                LazyVGrid(columns: cardGridColumns, alignment: .leading, spacing: 8) {
                    ForEach(0..<game.playerCards.count, id: \.self) { i in
                        PlayingCardView(face: .faceUp(game.playerCards[i]))
                            .id("\(game.roundToken)-p-\(i)")
                            .cardDealEntrance()
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: game.playerCards.count)
                Text("点数：\(playerPointsLabel)")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.primary.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSection: some View {
        let hasOutcome = !game.outcomeMessage.isEmpty
        return HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(hasOutcome ? statusColor : .secondary)
            Text(hasOutcome ? game.outcomeMessage : "等待本局结果")
                .font(.title3.weight(.semibold))
                .foregroundStyle(hasOutcome ? statusColor : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(statusColor.opacity(hasOutcome ? 0.14 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(statusColor.opacity(hasOutcome ? 0.28 : 0.08), lineWidth: 1)
        )
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("要牌") {
                GameFeedback.shared.buttonTap()
                Task { await game.hit() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .tint(.blue)
            .disabled(!canHit)
            .opacity(canHit ? 1 : 0.55)
            .saturation(canHit ? 1 : 0.2)

            Button("停牌") {
                GameFeedback.shared.buttonTap()
                Task { await game.stand() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .tint(.orange)
            .disabled(!canStand)
            .opacity(canStand ? 1 : 0.55)
            .saturation(canStand ? 1 : 0.2)

            Button(emphasizeForcedAllIn ? "强制全下" : "全下") {
                GameFeedback.shared.buttonTap()
                performMidHandAllIn()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .tint(emphasizeForcedAllIn ? .orange : .red.opacity(0.85))
            .disabled(!canMidHandAllIn)
            .opacity(canMidHandAllIn ? 1 : 0.55)
            .saturation(canMidHandAllIn ? 1 : 0.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canHit: Bool {
        game.phase == .playerTurn && !game.isAnimating
    }

    private var canStand: Bool {
        game.phase == .playerTurn && !game.isAnimating
    }

    private var dealerCardFaces: [PlayingCardView.Face] {
        guard game.dealerCards.count >= 2 else {
            return game.dealerCards.map { PlayingCardView.Face.faceUp($0) }
        }
        if game.hideDealerHoleCard {
            return game.dealerCards.enumerated().map { index, card in
                index == 1 ? .faceDown : .faceUp(card)
            }
        }
        return game.dealerCards.map { PlayingCardView.Face.faceUp($0) }
    }

    private var playerPointsLabel: String {
        game.playerCards.isEmpty ? "—" : "\(game.playerBestValue)"
    }

    private func visibleDealerValueText() -> String {
        if game.dealerCards.isEmpty { return "—" }
        return "\(game.dealerBestValue)"
    }

    private func dealerUpcardValueText() -> String {
        guard let first = game.dealerCards.first else { return "—" }
        return "\(Hand(cards: [first]).bestValue)"
    }

    private var statusColor: Color {
        if game.outcomeMessage.contains("平局") {
            return .orange
        }
        if game.outcomeMessage.contains("赢") {
            return .green
        }
        if game.outcomeMessage.contains("输") || game.outcomeMessage.contains("爆牌") {
            return .red
        }
        return .secondary
    }

    private var statusIcon: String {
        if game.outcomeMessage.contains("平局") {
            return "equal.circle.fill"
        }
        if game.outcomeMessage.contains("赢") {
            return "checkmark.circle.fill"
        }
        if game.outcomeMessage.contains("输") || game.outcomeMessage.contains("爆牌") {
            return "xmark.circle.fill"
        }
        return "hourglass.circle.fill"
    }

    private var cardGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 58, maximum: 58), spacing: 8, alignment: .leading)]
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
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
                Text("当前进度不会记入历史，双方筹码将重置。")
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
