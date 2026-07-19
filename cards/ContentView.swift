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
                Text("选择几副牌后进入对局；规则与庄家逻辑不变，无筹码。")
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
                    welcomeTag("庄家 17 停")
                    welcomeTag("练习节奏")
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
    let practiceMode: PracticeMode
    let onEndSession: () -> Void
    @State private var didAutoStart = false
    @State private var showRoundEndSheet = false

    init(practiceMode: PracticeMode, onEndSession: @escaping () -> Void) {
        self.practiceMode = practiceMode
        self.onEndSession = onEndSession
        _game = StateObject(wrappedValue: BlackjackGame(practiceMode: practiceMode))
    }

    var body: some View {
        ZStack {
            gameTableView
            if game.isShowingShuffleScreen {
                ShuffleScreenOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: game.isShowingShuffleScreen)
        .sheet(isPresented: $showRoundEndSheet) {
            roundEndSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .onChange(of: game.phase) { _, newPhase in
            if newPhase == .finished {
                showRoundEndSheet = true
            } else {
                showRoundEndSheet = false
            }
        }
        .onAppear {
            guard !didAutoStart else { return }
            didAutoStart = true
            Task { await game.startNewRound() }
        }
    }

    /// 本局结束后的弹窗：结果 +「新一局」；预留扩展区供后续筹码等展示。
    private var roundEndSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("本局结束")
                        .font(.title2.weight(.semibold))
                    Text(game.outcomeMessage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // 后续扩展：例如「本局筹码 +12」「余额 100」等，与 BlackjackGame 结算协调层对接即可。
                Text(game.shoeStatusLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.top, 16)

                Spacer(minLength: 24)

                Button {
                    GameFeedback.shared.buttonTap()
                    showRoundEndSheet = false
                    Task { await game.startNewRound() }
                } label: {
                    Text("新一局")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
        }
    }

    /// 牌面与状态区可滚动；底部仅保留要牌 / 停牌。新一局在本局结束弹窗内操作。
    private var gameTableView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    tableTitle
                    if game.phase == .idle && game.playerCards.isEmpty {
                        Text("使用下方「要牌」「停牌」进行游戏；每局结束后在弹窗中开新一局。")
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
            Button {
                GameFeedback.shared.buttonTap()
                onEndSession()
            } label: {
                Image(systemName: "chevron.backward.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回模式选择")

            VStack(alignment: .leading, spacing: 2) {
                Text("二十一点")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Text(game.shoeStatusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text("切牌点后重洗")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
                Text("庄家")
                    .font(.title3.weight(.semibold))
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
                Text("玩家")
                    .font(.title3.weight(.semibold))
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
