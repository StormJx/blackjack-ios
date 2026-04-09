//
//  ContentView.swift
//  cards
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = BlackjackGame()
    @State private var hasEnteredGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackgroundView()
                if hasEnteredGame {
                    gameTableView
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
            .animation(.easeInOut(duration: 0.28), value: hasEnteredGame)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var gameTableView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                tableTitle
                if game.phase == .idle && game.playerCards.isEmpty {
                    Text("点击下方「新一局」开始")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let caption = game.dealingCaption {
                    Text(caption)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .animation(.easeInOut(duration: 0.22), value: game.dealingCaption)
                }
                VStack(spacing: 14) {
                    dealerSection
                    playerSection
                    statusSection
                }
                .opacity(game.handAreaOpacity)
                .scaleEffect(game.handAreaScale, anchor: .center)
                .animation(.easeInOut(duration: 0.35), value: game.handAreaOpacity)
                controls
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .top)
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

    private var welcomeView: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Text("二十一点")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("练习模式")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("单副牌规则，点击开始后进入对局。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                HStack(spacing: 8) {
                    welcomeTag("单副牌")
                    welcomeTag("庄家 17 停")
                    welcomeTag("练习节奏")
                }
                .padding(.top, 2)
                Button("开始游戏") {
                    GameFeedback.shared.buttonTap()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        hasEnteredGame = true
                    }
                    Task { await game.startNewRound() }
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

    private var tableTitle: some View {
        HStack {
            Text("二十一点")
                .font(.system(.title2, design: .rounded).weight(.heavy))
            Spacer(minLength: 0)
            Text("练习模式")
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
        VStack(alignment: .leading, spacing: 0) {
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

            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.vertical, 6)

                Button("新一局") {
                    GameFeedback.shared.buttonTap()
                    Task { await game.startNewRound() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .tint(.green)
                .disabled(!canStartNewRound)
                .opacity(canStartNewRound ? 1 : 0.55)
                .saturation(canStartNewRound ? 1 : 0.2)
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canHit: Bool {
        game.phase == .playerTurn && !game.isAnimating
    }

    private var canStand: Bool {
        game.phase == .playerTurn && !game.isAnimating
    }

    private var canStartNewRound: Bool {
        !game.isAnimating && (game.phase == .idle || game.phase == .finished)
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
