//
//  DailyGoals.swift
//  cards
//
//  R1：每日一组目标。完成给徽章，不给筹码。
//

import Foundation

struct DailyGoalSnapshot: Equatable, Codable, Sendable {
    var dayKey: String
    var entertainmentWins: Int
    var cleanHands: Int
    var streak: Int
    var lastAwardedDay: String?

    static func empty(dayKey: String) -> DailyGoalSnapshot {
        DailyGoalSnapshot(
            dayKey: dayKey,
            entertainmentWins: 0,
            cleanHands: 0,
            streak: 0,
            lastAwardedDay: nil
        )
    }
}

enum DailyGoalRules {
    static let entertainmentWinTarget = 3
    static let cleanHandTarget = 5
    static let storageKey = "dailyGoals.snapshot"

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func previousDayKey(before dayKey: String, calendar: Calendar = .current) -> String? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = calendar.date(from: components),
              let previous = calendar.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return self.dayKey(for: previous, calendar: calendar)
    }

    static func isComplete(_ snapshot: DailyGoalSnapshot) -> Bool {
        snapshot.entertainmentWins >= entertainmentWinTarget
            || snapshot.cleanHands >= cleanHandTarget
    }

    static func progressLine(_ snapshot: DailyGoalSnapshot) -> String {
        L10n.format(
            "stats.daily.progressFormat",
            min(snapshot.entertainmentWins, entertainmentWinTarget),
            entertainmentWinTarget,
            min(snapshot.cleanHands, cleanHandTarget),
            cleanHandTarget
        )
    }

    static func streakLine(_ snapshot: DailyGoalSnapshot) -> String {
        L10n.format("stats.daily.streakFormat", snapshot.streak)
    }
}

@MainActor
final class DailyGoalStore: ObservableObject {
    @Published private(set) var snapshot: DailyGoalSnapshot

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar
        if let data = defaults.data(forKey: DailyGoalRules.storageKey),
           let decoded = try? JSONDecoder().decode(DailyGoalSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = .empty(dayKey: DailyGoalRules.dayKey(for: now, calendar: calendar))
        }
        roll(to: DailyGoalRules.dayKey(for: now, calendar: calendar))
    }

    /// 记一局。新达成当日目标时返回徽章文案，否则 nil。不改筹码。
    @discardableResult
    func record(playStyle: PlayStyle, outcome: RoundOutcome, playerBusted: Bool, now: Date = Date()) -> String? {
        roll(to: DailyGoalRules.dayKey(for: now, calendar: calendar))
        if playStyle == .entertainment, outcome == .playerWin || outcome == .playerBlackjack {
            snapshot.entertainmentWins += 1
        }
        if !playerBusted {
            snapshot.cleanHands += 1
        }
        let notice = awardIfNeeded()
        persist()
        return notice
    }

    private func roll(to today: String) {
        guard snapshot.dayKey != today else { return }
        let yesterday = DailyGoalRules.previousDayKey(before: today, calendar: calendar)
        if snapshot.lastAwardedDay != yesterday && snapshot.lastAwardedDay != today {
            snapshot.streak = 0
        }
        snapshot.dayKey = today
        snapshot.entertainmentWins = 0
        snapshot.cleanHands = 0
    }

    private func awardIfNeeded() -> String? {
        guard DailyGoalRules.isComplete(snapshot) else { return nil }
        guard snapshot.lastAwardedDay != snapshot.dayKey else { return nil }
        let yesterday = DailyGoalRules.previousDayKey(before: snapshot.dayKey, calendar: calendar)
        if snapshot.lastAwardedDay == yesterday {
            snapshot.streak += 1
        } else {
            snapshot.streak = 1
        }
        snapshot.lastAwardedDay = snapshot.dayKey
        return L10n.t("stats.daily.awardNotice")
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: DailyGoalRules.storageKey)
        }
    }
}
