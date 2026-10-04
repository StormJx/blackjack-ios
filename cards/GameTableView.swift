//
//  GameTableView.swift
//  cards
//
//  D10 / E1 / E4：牌桌子视图（标题 / 手牌区 / 弱结果条 / 操作键）。
//

import SwiftUI

struct GameTableView: View {
    @ObservedObject var game: BlackjackGame
    @ObservedObject var chipBank: ChipBank
    let playStyle: PlayStyle
    let sessionStageLevel: Int
    let sessionDealerStart: Int
    let showBetPanel: Bool
    let showRoundEndPanel: Bool
    let canHit: Bool
    let canStand: Bool
    let canDoubleDown: Bool
    var doubleDownDisabledReason: String? = nil
    let canSurrender: Bool
    var surrenderDisabledReason: String? = nil
    let canSplit: Bool
    var splitDisabledReason: String? = nil
    /// 娱乐模式且设置开启时的弱策略句。闯关不传。
    var actionHint: String? = nil
    /// 娱乐模式 + 已解锁道具时为 true。
    let showsMidHandAllIn: Bool
    let canMidHandAllIn: Bool
    var midHandAllInDisabledReason: String? = nil
    let emphasizeForcedAllIn: Bool
    let showsPeekHole: Bool
    let canPeekHole: Bool
    var peekHoleDisabledReason: String? = nil
    let showsSoft17Hit: Bool
    let canSoft17Hit: Bool
    let soft17HitActive: Bool
    var soft17HitDisabledReason: String? = nil
    let showsRedrawOne: Bool
    let canRedrawOne: Bool
    var redrawOneDisabledReason: String? = nil
    let showsReshuffleDealerCard: Bool
    let canReshuffleDealerCard: Bool
    var reshuffleDealerDisabledReason: String? = nil
    /// E4：确认下注后短暂放大余额行。
    let chipBalancePulse: Bool
    var cardBack: CardBackStyle = .classicNavy
    let onHit: () -> Void
    let onStand: () -> Void
    let onDoubleDown: () -> Void
    let onSurrender: () -> Void
    let onSplit: () -> Void
    let onAllIn: () -> Void
    let onPeekHole: () -> Void
    let onSoft17Hit: () -> Void
    let onRedrawOne: () -> Void
    let onReshuffleDealerCard: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    tableTitle
                    if game.phase == .idle && game.playerCards.isEmpty && !showBetPanel {
                        Text(idleHint)
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
                ViewThatFits(in: .vertical) {
                    controls
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, 14)
                    ScrollView {
                        controls
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, 14)
                    }
                    .frame(maxHeight: 260)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            Color(red: 0.12, green: 0.42, blue: 0.28)
                                .opacity(colorScheme == .dark ? 0.22 : 0.10)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Color(red: 0.18, green: 0.50, blue: 0.32).opacity(0.35),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var idleHint: String {
        L10n.t("table.idleHint")
    }

    private var tableTitle: some View {
        HStack(alignment: .center, spacing: 10) {
            // 占位与会话级退出按钮同宽，避免标题左移；真正的叉号在外层 overlay。
            Color.clear
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("welcome.appTitle"))
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Text(game.shoeStatusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if playStyle.showsChips {
                    Text(TableHUD.goalLine(playStyle: playStyle, level: sessionStageLevel))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    HStack(spacing: 8) {
                        Text(L10n.format("table.youFormat", chipBank.balance))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                        Text(L10n.format("table.dealerFormat", chipBank.dealerBank))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                        if chipBank.splitSecondBet > 0 {
                            Text(L10n.format("table.betSplitFormat", chipBank.activeBet, chipBank.splitSecondBet))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        } else if chipBank.activeBet > 0 {
                            Text(L10n.format("table.betFormat", chipBank.activeBet))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                        if chipBank.activeInsurance > 0 {
                            Text(L10n.format("insurance.amountFormat", chipBank.activeInsurance))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .scaleEffect(chipBalancePulse ? 1.08 : 1)
                    .animation(.spring(response: 0.36, dampingFraction: 0.7), value: chipBalancePulse)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(chipBalanceAccessibilityLabel)
                    dealerBankMeter
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(game.practiceMode.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
                if playStyle == .entertainment {
                    Text(L10n.t("badge.entertainment"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                } else {
                    Text(L10n.t("badge.challenge"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var dealerSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("common.dealer"))
                    .font(.title3.weight(.semibold))
                LazyVGrid(columns: cardGridColumns, alignment: .leading, spacing: 8) {
                    ForEach(0..<dealerCardFaces.count, id: \.self) { i in
                        PlayingCardView(face: dealerCardFaces[i], cardBack: cardBack)
                            .id("\(game.roundToken)-d-\(i)-\(dealerCardIdentity(i))")
                            .cardDealEntrance()
                            .scaleEffect(game.reshufflePulseIndex == i ? 1.12 : 1)
                            .animation(
                                .spring(response: 0.32, dampingFraction: 0.55),
                                value: game.reshufflePulseIndex == i
                            )
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: dealerCardFaces.count)
                .animation(.easeInOut(duration: 0.32), value: game.dealerHoleRevealed)
                if !game.hideDealerHoleCard || game.phase == .idle {
                    Text(L10n.format("table.pointsFormat", visibleDealerValueText))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary.opacity(0.78))
                        .accessibilityLabel(
                            L10n.format("table.a11y.dealerPointsFormat", visibleDealerValueText)
                        )
                } else {
                    Text(L10n.format("table.upcardPointsFormat", dealerUpcardValueText))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.primary.opacity(0.78))
                        .accessibilityLabel(
                            L10n.format(
                                "table.a11y.dealerUpcardPointsFormat",
                                dealerUpcardValueText
                            )
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var dealerBankMeter: some View {
        if playStyle.showsChips, sessionDealerStart > 0, chipBank.activeBet > 0 || game.phase != .idle {
            let fraction = TableHUD.dealerBankFraction(
                remaining: chipBank.dealerBank,
                capacity: sessionDealerStart
            )
            DealerBankMeter(
                fraction: fraction,
                accessibilityText: L10n.format("table.dealerMeterA11y", Int((fraction * 100).rounded()))
            )
            .frame(height: 6)
        }
    }

    private var playerSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 10) {
                if game.splitFirstHand.isEmpty && game.splitPendingCard == nil {
                    singlePlayerHand
                } else {
                    splitHandRow(
                        index: 1,
                        cards: game.splitFirstHand.isEmpty ? game.playerCards : game.splitFirstHand,
                        active: game.splitFirstHand.isEmpty && game.phase == .playerTurn
                    )
                    splitHandRow(
                        index: 2,
                        cards: game.splitFirstHand.isEmpty
                            ? (game.splitPendingCard.map { [$0] } ?? [])
                            : game.playerCards,
                        active: !game.splitFirstHand.isEmpty && game.phase == .playerTurn
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var singlePlayerHand: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("common.player"))
                .font(.title3.weight(.semibold))
            cardRow(game.playerCards, identityPrefix: "p")
            Text(L10n.format("table.pointsFormat", playerPointsLabel))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(0.78))
                .accessibilityLabel(
                    L10n.format("table.a11y.playerPointsFormat", playerPointsLabel)
                )
        }
    }

    private func splitHandRow(index: Int, cards: [Card], active: Bool) -> some View {
        let points = cards.isEmpty ? "—" : "\(Hand(cards: cards).bestValue)"
        return VStack(alignment: .leading, spacing: 6) {
            Text(L10n.format("table.splitHandFormat", index, points))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? Color.primary : Color.secondary)
            cardRow(cards, identityPrefix: "s\(index)")
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Color.primary.opacity(0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(active ? Color.primary.opacity(0.18) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func cardRow(_ cards: [Card], identityPrefix: String) -> some View {
        LazyVGrid(columns: cardGridColumns, alignment: .leading, spacing: 8) {
            ForEach(0..<cards.count, id: \.self) { i in
                PlayingCardView(face: .faceUp(cards[i]))
                    .id("\(game.roundToken)-\(identityPrefix)-\(i)")
                    .cardDealEntrance()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: cards.count)
    }

    private var statusSection: some View {
        // 局末弹窗已展示完整结果时，牌桌结果区只保留弱提示，避免双份重复。
        let sheetOwnsResult = game.phase == .finished || showRoundEndPanel
        let peeking = game.isPeekingHoleCard
        let propHint = game.propActionHint
        let hasOutcome = game.lastOutcome != nil && !sheetOwnsResult
        let color = game.lastOutcome?.statusColor ?? .secondary
        let icon = game.lastOutcome?.statusIconName ?? TableHUD.phaseStatusIcon(phase: game.phase)
        let statusText: String = {
            if peeking { return L10n.t("table.peeking") }
            if sheetOwnsResult { return L10n.t("table.roundOver") }
            if hasOutcome { return game.outcomeMessage }
            if let propHint { return propHint }
            return TableHUD.phaseStatusLine(phase: game.phase)
        }()
        let statusColor: Color = {
            if peeking { return .orange }
            if hasOutcome { return color }
            if propHint != nil { return .orange }
            return .secondary
        }()
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: peeking
                      ? "eye.fill"
                      : (sheetOwnsResult ? "checkmark.circle" : (propHint != nil ? "arrow.triangle.2.circlepath" : icon)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
                Text(statusText)
                    .font(sheetOwnsResult ? .subheadline.weight(.medium) : .title3.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            if peeking {
                PeekCountdownBar()
                    .frame(height: 4)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(statusColor.opacity(hasOutcome || propHint != nil || peeking ? 0.14 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(statusColor.opacity(hasOutcome || propHint != nil || peeking ? 0.28 : 0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusText)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if let actionHint {
                Text(actionHint)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(actionHint)
            }
            HStack(spacing: 12) {
                Button(L10n.t("action.hit")) {
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
                .accessibilityHint(
                    canHit
                        ? L10n.t("action.a11y.hitHint")
                        : L10n.t("action.a11y.hitDisabled")
                )

                Button(L10n.t("action.stand")) {
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
                .accessibilityHint(
                    canStand
                        ? L10n.t("action.a11y.standHint")
                        : L10n.t("action.a11y.standDisabled")
                )
            }

            HStack(spacing: 12) {
                Button(L10n.t("action.double")) {
                    GameFeedback.shared.buttonTap()
                    onDoubleDown()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .tint(.green)
                .disabled(!canDoubleDown)
                .opacity(canDoubleDown ? 1 : 0.55)
                .saturation(canDoubleDown ? 1 : 0.2)
                .accessibilityHint(
                    canDoubleDown
                        ? L10n.t("action.a11y.doubleHint")
                        : (doubleDownDisabledReason ?? L10n.t("action.a11y.doubleDisabled"))
                )

                Button(L10n.t("action.surrender")) {
                    GameFeedback.shared.buttonTap()
                    onSurrender()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .tint(.gray)
                .disabled(!canSurrender)
                .opacity(canSurrender ? 1 : 0.55)
                .saturation(canSurrender ? 1 : 0.2)
                .accessibilityHint(
                    canSurrender
                        ? L10n.t("action.a11y.surrenderHint")
                        : (surrenderDisabledReason ?? L10n.t("action.a11y.surrenderDisabled"))
                )

                if game.canOfferSplit || canSplit {
                    Button(L10n.t("action.split")) {
                        GameFeedback.shared.buttonTap()
                        onSplit()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .tint(.purple)
                    .disabled(!canSplit)
                    .opacity(canSplit ? 1 : 0.55)
                    .saturation(canSplit ? 1 : 0.2)
                    .accessibilityHint(
                        canSplit
                            ? L10n.t("action.a11y.splitHint")
                            : (splitDisabledReason ?? L10n.t("action.a11y.splitDisabled"))
                    )
                }

                if showsMidHandAllIn {
                    Button(midHandAllInTitle) {
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
                    .accessibilityLabel(midHandAllInTitle)
                    .accessibilityHint(
                        canMidHandAllIn
                            ? L10n.t("action.a11y.midHandAllInHint")
                            : (midHandAllInDisabledReason ?? L10n.t("disabled.unavailable"))
                    )
                }
            }

            if showsPeekHole || showsSoft17Hit || showsRedrawOne || showsReshuffleDealerCard {
                LazyVGrid(columns: propButtonColumns, spacing: 10) {
                    if showsPeekHole {
                        propButton(
                            title: L10n.t("prop.short.peek"),
                            enabled: canPeekHole,
                            disabledReason: peekHoleDisabledReason,
                            enabledHint: L10n.t("prop.a11y.peekHint"),
                            action: onPeekHole
                        )
                    }
                    if showsSoft17Hit {
                        propButton(
                            title: soft17HitActive
                                ? L10n.t("prop.short.soft17On")
                                : L10n.t("prop.short.soft17"),
                            enabled: canSoft17Hit,
                            disabledReason: soft17HitDisabledReason,
                            enabledHint: L10n.t("prop.a11y.soft17Hint"),
                            action: onSoft17Hit
                        )
                    }
                    if showsRedrawOne {
                        propButton(
                            title: L10n.t("prop.short.redraw"),
                            enabled: canRedrawOne,
                            disabledReason: redrawOneDisabledReason,
                            enabledHint: L10n.t("prop.a11y.redrawHint"),
                            action: onRedrawOne
                        )
                    }
                    if showsReshuffleDealerCard {
                        propButton(
                            title: L10n.t("prop.short.reshuffleDealer"),
                            enabled: canReshuffleDealerCard,
                            disabledReason: reshuffleDealerDisabledReason,
                            enabledHint: L10n.t("prop.a11y.reshuffleDealerHint"),
                            action: onReshuffleDealerCard
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var midHandAllInTitle: String {
        emphasizeForcedAllIn ? L10n.t("action.forceAllIn") : L10n.t("action.allIn")
    }

    private func propButton(
        title: String,
        enabled: Bool,
        disabledReason: String? = nil,
        enabledHint: String = L10n.t("prop.a11y.available"),
        action: @escaping () -> Void
    ) -> some View {
        Button(title) {
            GameFeedback.shared.buttonTap()
            action()
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(maxWidth: .infinity)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
        .accessibilityLabel(title)
        .accessibilityHint(enabled ? enabledHint : (disabledReason ?? L10n.t("disabled.unavailable")))
    }

    private var chipBalanceAccessibilityLabel: String {
        if chipBank.activeBet > 0 {
            let stake = chipBank.activeBet + chipBank.splitSecondBet
            if chipBank.activeInsurance > 0 {
                return L10n.format(
                    "table.a11y.chipsFullFormat",
                    chipBank.balance,
                    chipBank.dealerBank,
                    stake,
                    chipBank.activeInsurance
                )
            }
            return L10n.format(
                "table.a11y.chipsBetFormat",
                chipBank.balance,
                chipBank.dealerBank,
                stake
            )
        }
        return L10n.format("table.a11y.chipsFormat", chipBank.balance, chipBank.dealerBank)
    }

    private var propButtonColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]
    }

    private func dealerCardIdentity(_ index: Int) -> String {
        guard game.dealerCards.indices.contains(index) else { return "\(index)" }
        let card = game.dealerCards[index]
        return "\(card.suit.rawValue)-\(card.rank.shortName)"
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

/// UX6：窥视约 1 秒倒计时条（与 BlackjackGame.delayPeekHole 对齐）。
private struct PeekCountdownBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.orange.opacity(0.18))
                Capsule(style: .continuous)
                    .fill(Color.orange.opacity(0.85))
                    .frame(width: max(4, geo.size.width * progress))
            }
        }
        .onAppear {
            progress = 1
            if reduceMotion {
                progress = 0
                return
            }
            withAnimation(.linear(duration: 1.0)) {
                progress = 0
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DealerBankMeter: View {
    let fraction: Double
    let accessibilityText: String

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.12))
                Capsule(style: .continuous)
                    .fill(Color(red: 0.18, green: 0.55, blue: 0.32))
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}
