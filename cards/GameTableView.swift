//
//  GameTableView.swift
//  cards
//
//  D10：牌桌子视图（标题 / 手牌区 / 弱结果条 / 操作键）。
//

import SwiftUI

struct GameTableView: View {
    @ObservedObject var game: BlackjackGame
    @ObservedObject var chipBank: ChipBank
    let showBetPanel: Bool
    let showRoundEndPanel: Bool
    let canHit: Bool
    let canStand: Bool
    /// 道具预留：默认 `false`；为 true 时显示见牌后「全下」。
    let showsMidHandAllIn: Bool
    let canMidHandAllIn: Bool
    let emphasizeForcedAllIn: Bool
    let onHit: () -> Void
    let onStand: () -> Void
    let onAllIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    tableTitle
                    if game.phase == .idle && game.playerCards.isEmpty && !showBetPanel {
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
            // 占位与会话级退出按钮同宽，避免标题左移；真正的叉号在外层 overlay。
            Color.clear
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

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
                    Text("点数：\(visibleDealerValueText)")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary.opacity(0.78))
                } else {
                    Text("明牌点数：\(dealerUpcardValueText)")
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
        // 局末弹窗已展示完整结果时，牌桌结果区只保留弱提示，避免双份重复。
        let sheetOwnsResult = game.phase == .finished || showRoundEndPanel
        let hasOutcome = game.lastOutcome != nil && !sheetOwnsResult
        let color = game.lastOutcome?.statusColor ?? .secondary
        let icon = game.lastOutcome?.statusIconName ?? "hourglass.circle.fill"
        return HStack(spacing: 8) {
            Image(systemName: sheetOwnsResult ? "checkmark.circle" : icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(hasOutcome ? color : .secondary)
            Text(sheetOwnsResult ? "本局已结束" : (hasOutcome ? game.outcomeMessage : "等待本局结果"))
                .font(sheetOwnsResult ? .subheadline.weight(.medium) : .title3.weight(.semibold))
                .foregroundStyle(hasOutcome ? color : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(hasOutcome ? 0.14 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(hasOutcome ? 0.28 : 0.08), lineWidth: 1)
        )
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("要牌") {
                GameFeedback.shared.buttonTap()
                onHit()
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
                onStand()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .tint(.orange)
            .disabled(!canStand)
            .opacity(canStand ? 1 : 0.55)
            .saturation(canStand ? 1 : 0.2)

            // 默认隐藏；道具「见牌后再全下」开启后显示（逻辑见 ChipBank.goAllIn）。
            if showsMidHandAllIn {
                Button(emphasizeForcedAllIn ? "强制全下" : "全下") {
                    GameFeedback.shared.buttonTap()
                    onAllIn()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .tint(emphasizeForcedAllIn ? .orange : .red.opacity(0.85))
                .disabled(!canMidHandAllIn)
                .opacity(canMidHandAllIn ? 1 : 0.55)
                .saturation(canMidHandAllIn ? 1 : 0.2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var visibleDealerValueText: String {
        game.dealerCards.isEmpty ? "—" : "\(game.dealerBestValue)"
    }

    private var dealerUpcardValueText: String {
        guard let first = game.dealerCards.first else { return "—" }
        return "\(Hand(cards: [first]).bestValue)"
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
