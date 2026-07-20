//
//  GameFeedback.swift
//  cards
//

import AVFoundation
import UIKit

/// 音效基名与路径说明见仓库根目录 `VERSION_ROADMAP.txt`「音效资源说明」。
enum GameSound: String, CaseIterable {
    case deal
    case flip
    case win
    case lose
    case push
    case shuffle
}

@MainActor
final class GameFeedback {
    static let shared = GameFeedback()

    /// 由 AppSettings / 设置页同步；默认开启
    var soundEnabled = true
    var hapticsEnabled = true

    private var audioRetention: [AVAudioPlayer] = []
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        configureAudioSession()
        impactLight.prepare()
        impactMedium.prepare()
        notification.prepare()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: - 音效

    func play(_ sound: GameSound) {
        guard soundEnabled else { return }
        guard let url = Self.bundleURL(for: sound.rawValue) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioRetention.append(player)
            player.play()
            let retained = player
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                audioRetention.removeAll { $0 === retained }
            }
        } catch {}
    }

    private static func bundleURL(for baseName: String) -> URL? {
        let exts = ["mp3", "m4a", "wav", "caf"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Sounds") {
                return url
            }
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    // MARK: - 触觉

    func lightImpact() {
        guard hapticsEnabled else { return }
        impactLight.impactOccurred(intensity: 0.65)
    }

    func mediumImpact() {
        guard hapticsEnabled else { return }
        impactMedium.impactOccurred(intensity: 0.85)
    }

    func notifySuccess() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func notifyWarning() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    func notifyError() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }

    /// 按钮轻触（仅触觉）
    func buttonTap() {
        lightImpact()
    }

    // MARK: - 组合（游戏内调用）

    func cardDealt() {
        play(.deal)
        lightImpact()
    }

    func holeRevealed() {
        play(.flip)
        mediumImpact()
    }

    func shuffleHint() {
        play(.shuffle)
        lightImpact()
    }

    func roundOutcome(playerWon: Bool?, isPush: Bool) {
        if isPush {
            play(.push)
            notifyWarning()
        } else if playerWon == true {
            play(.win)
            notifySuccess()
        } else {
            play(.lose)
            notifyError()
        }
    }

    // MARK: - 筹码映射（E4：复用既有基名，不新增音效文件名）

    /// 确认下注落注。
    func betPlaced() {
        play(.deal)
        mediumImpact()
    }

    /// 局末玩家净赢筹码。
    func chipsPaid() {
        play(.win)
        notifySuccess()
    }

    /// 局末玩家净亏筹码。
    func chipsLost() {
        play(.lose)
        notifyError()
    }

    /// 平局退注（筹码无净变化）。
    func chipsPushed() {
        play(.push)
        notifyWarning()
    }

    /// 按结算净变化映射筹码反馈（快速模式勿调用）。
    func chipsSettled(netChange: Int) {
        if netChange > 0 {
            chipsPaid()
        } else if netChange < 0 {
            chipsLost()
        } else {
            chipsPushed()
        }
    }
}
