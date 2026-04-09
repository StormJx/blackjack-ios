//
//  CardDealEntrance.swift
//  cards
//

import SwiftUI

/// 单张牌入场：自上方略带回弹，与 ViewModel 的 spring 配合使用
struct CardDealEntrance: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.68, anchor: .center)
            .offset(y: appeared ? 0 : -42)
            .rotationEffect(.degrees(appeared ? 0 : 6))
            .opacity(appeared ? 1 : 0.15)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.68)) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func cardDealEntrance() -> some View {
        modifier(CardDealEntrance())
    }
}
