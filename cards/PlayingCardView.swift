//
//  PlayingCardView.swift
//  cards
//
//  P7：精致矢量牌面（经典点阵 / 人头牌 / 牌背），无位图资源依赖。
//

import SwiftUI

extension Suit {
    var uiColor: Color {
        switch self {
        case .hearts, .diamonds: return Color(red: 0.78, green: 0.12, blue: 0.14)
        case .spades, .clubs: return Color(white: 0.12)
        }
    }

    /// SF Symbol 花色（用于点阵与牌背装饰）。
    var symbolName: String {
        switch self {
        case .spades: return "suit.spade.fill"
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        }
    }
}

/// 单张扑克牌展示：正面为经典牌面布局，背面为牌背图案（暗牌）。
struct PlayingCardView: View {
    enum Face: Equatable {
        case faceUp(Card)
        case faceDown
    }

    let face: Face
    var width: CGFloat = 58
    var height: CGFloat = 82
    /// 牌背样式（外观）；默认经典海军蓝。
    var cardBack: CardBackStyle = .classicNavy

    var body: some View {
        Group {
            switch face {
            case .faceUp(let card):
                faceUpBody(card: card)
            case .faceDown:
                faceDownBody(style: cardBack)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch face {
        case .faceUp(let card):
            return "\(card.rank.shortName)\(card.suit.rawValue)"
        case .faceDown:
            return "扣着的牌"
        }
    }

    // MARK: - Face up

    private func faceUpBody(card: Card) -> some View {
        let color = card.suit.uiColor
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(white: 0.99))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.black.opacity(0.14), lineWidth: 1)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    cornerStack(rank: card.rank, suit: card.suit, color: color)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                centerArt(card: card, color: color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    cornerStack(rank: card.rank, suit: card.suit, color: color)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
        }
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
    }

    private func cornerStack(rank: Rank, suit: Suit, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(rank.shortName)
                .font(.system(size: rank == .ten ? 9 : 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Image(systemName: suit.symbolName)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .frame(width: 14)
    }

    @ViewBuilder
    private func centerArt(card: Card, color: Color) -> some View {
        switch card.rank {
        case .ace:
            Image(systemName: card.suit.symbolName)
                .font(.system(size: min(width * 0.46, 30), weight: .regular))
                .foregroundStyle(color)
        case .jack, .queen, .king:
            faceCardCenter(rank: card.rank, suit: card.suit, color: color)
        default:
            pipGrid(rank: card.rank, suit: card.suit, color: color)
        }
    }

    private func faceCardCenter(rank: Rank, suit: Suit, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(color.opacity(0.35), lineWidth: 1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)

            VStack(spacing: 2) {
                Text(rank.shortName)
                    .font(.system(size: min(width * 0.34, 22), weight: .bold, design: .serif))
                    .foregroundStyle(color)
                Image(systemName: suit.symbolName)
                    .font(.system(size: min(width * 0.2, 13), weight: .semibold))
                    .foregroundStyle(color.opacity(0.85))
            }
        }
    }

    /// 经典扑克点阵（相对坐标：列 -1…1，行 -1…1）。
    private func pipGrid(rank: Rank, suit: Suit, color: Color) -> some View {
        let points = Self.pipPositions(for: rank)
        let pipSize = min(width * 0.18, 12)
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    let upright = point.y <= 0.05
                    Image(systemName: suit.symbolName)
                        .font(.system(size: pipSize, weight: .regular))
                        .foregroundStyle(color)
                        .rotationEffect(.degrees(upright ? 0 : 180))
                        .position(
                            x: w * 0.5 + point.x * w * 0.32,
                            y: h * 0.5 + point.y * h * 0.38
                        )
                }
            }
        }
    }

    private static func pipPositions(for rank: Rank) -> [CGPoint] {
        switch rank {
        case .ace:
            return [.zero]
        case .two:
            return [CGPoint(x: 0, y: -1), CGPoint(x: 0, y: 1)]
        case .three:
            return [CGPoint(x: 0, y: -1), .zero, CGPoint(x: 0, y: 1)]
        case .four:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .five:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                .zero,
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .six:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .seven:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: 0, y: -0.5),
                CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .eight:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: 0, y: -0.45),
                CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
                CGPoint(x: 0, y: 0.45),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .nine:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: -1, y: -0.33), CGPoint(x: 1, y: -0.33),
                .zero,
                CGPoint(x: -1, y: 0.33), CGPoint(x: 1, y: 0.33),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .ten:
            return [
                CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                CGPoint(x: 0, y: -0.66),
                CGPoint(x: -1, y: -0.33), CGPoint(x: 1, y: -0.33),
                CGPoint(x: -1, y: 0.33), CGPoint(x: 1, y: 0.33),
                CGPoint(x: 0, y: 0.66),
                CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1),
            ]
        case .jack, .queen, .king:
            return []
        }
    }

    // MARK: - Face down

    private func faceDownBody(style: CardBackStyle) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(backGradient(style))

            backPattern(style)
                .opacity(0.28)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(6)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(5)

            Image(systemName: backCenterSymbol(style))
                .font(.system(size: width * 0.24))
                .foregroundStyle(.white.opacity(0.28))
                .rotationEffect(.degrees(style == .crimsonRibbon ? 0 : 18))
        }
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
    }

    private func backGradient(_ style: CardBackStyle) -> LinearGradient {
        switch style {
        case .classicNavy:
            return LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.24, blue: 0.55),
                    Color(red: 0.07, green: 0.12, blue: 0.36),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emeraldLattice:
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.42, blue: 0.28),
                    Color(red: 0.05, green: 0.24, blue: 0.16),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .crimsonRibbon:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.12, blue: 0.20),
                    Color(red: 0.32, green: 0.06, blue: 0.12),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private func backCenterSymbol(_ style: CardBackStyle) -> String {
        switch style {
        case .classicNavy: return "suit.diamond.fill"
        case .emeraldLattice: return "suit.club.fill"
        case .crimsonRibbon: return "suit.heart.fill"
        }
    }

    @ViewBuilder
    private func backPattern(_ style: CardBackStyle) -> some View {
        switch style {
        case .classicNavy:
            CardBackHatchPattern(diagonal: true)
        case .emeraldLattice:
            CardBackLatticePattern()
        case .crimsonRibbon:
            CardBackRibbonPattern()
        }
    }
}

/// 牌背斜纹（经典海军蓝）。
private struct CardBackHatchPattern: View {
    var diagonal: Bool = true

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 6
            var path = Path()
            let span = size.width + size.height
            var offset: CGFloat = -span
            while offset < span {
                if diagonal {
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                }
                offset += step
            }
            context.stroke(path, with: .color(.white), lineWidth: 0.8)
        }
    }
}

/// 翠绿格纹。
private struct CardBackLatticePattern: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 7
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(.white), lineWidth: 0.7)
        }
    }
}

/// 绯红缎带环。
private struct CardBackRibbonPattern: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                    .frame(width: w * 0.72, height: h * 0.22)
                    .rotationEffect(.degrees(-18))
                Capsule()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                    .frame(width: w * 0.72, height: h * 0.22)
                    .rotationEffect(.degrees(18))
            }
            .frame(width: w, height: h)
        }
    }
}

#Preview("牌面抽样") {
    let samples: [Card] = [
        Card(suit: .spades, rank: .ace),
        Card(suit: .hearts, rank: .seven),
        Card(suit: .clubs, rank: .king),
    ]
    return VStack(spacing: 16) {
        HStack(spacing: 10) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, card in
                PlayingCardView(face: .faceUp(card))
            }
        }
        HStack(spacing: 10) {
            ForEach(CardBackStyle.allCases) { style in
                VStack(spacing: 4) {
                    PlayingCardView(face: .faceDown, cardBack: style)
                    Text(style.title)
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    .padding()
    .background(Color(red: 0.1, green: 0.45, blue: 0.28))
}
