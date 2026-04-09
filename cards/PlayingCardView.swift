//
//  PlayingCardView.swift
//  cards
//

import SwiftUI

extension Suit {
    var uiColor: Color {
        switch self {
        case .hearts, .diamonds: return Color(red: 0.78, green: 0.12, blue: 0.14)
        case .spades, .clubs: return Color(white: 0.12)
        }
    }
}

/// 单张扑克牌展示：正面为经典牌面布局，背面为牌背图案（暗牌）
struct PlayingCardView: View {
    enum Face: Equatable {
        case faceUp(Card)
        case faceDown
    }

    let face: Face
    var width: CGFloat = 58
    var height: CGFloat = 82

    var body: some View {
        Group {
            switch face {
            case .faceUp(let card):
                faceUpBody(card: card)
            case .faceDown:
                faceDownBody()
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

    private func faceUpBody(card: Card) -> some View {
        let color = card.suit.uiColor
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(white: 0.99))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    cornerStack(rank: card.rank, suit: card.suit, color: color)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                Text(card.suit.rawValue)
                    .font(.system(size: min(width * 0.42, 34), weight: .regular, design: .serif))
                    .foregroundStyle(color)
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    cornerStack(rank: card.rank, suit: card.suit, color: color)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(5)
        }
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
    }

    private func cornerStack(rank: Rank, suit: Suit, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(rank.shortName)
                .font(.system(size: rank == .ten ? 10 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(suit.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func faceDownBody() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.22, blue: 0.52),
                            Color(red: 0.08, green: 0.14, blue: 0.38),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(5)

            // 简单对称装饰，暗示「牌背」
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: width * 0.22))
                .foregroundStyle(.white.opacity(0.18))
                .rotationEffect(.degrees(12))
        }
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
    }
}

#Preview("牌面") {
    HStack(spacing: 12) {
        PlayingCardView(face: .faceUp(Card(suit: .spades, rank: .ace)))
        PlayingCardView(face: .faceUp(Card(suit: .hearts, rank: .king)))
        PlayingCardView(face: .faceUp(Card(suit: .diamonds, rank: .ten)))
        PlayingCardView(face: .faceDown)
    }
    .padding()
    .background(Color(red: 0.1, green: 0.45, blue: 0.28))
}
