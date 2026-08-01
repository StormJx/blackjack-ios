//
//  DataSchema.swift
//  cards
//
//  A2：UserDefaults 持久化 schema 版本；升级时在此集中写迁移。
//  约定：凡改动持久化结构（键名 / 语义 / 成就枚举 rawValue 等），必须递增
//  `currentVersion`，并在 `runMigrations` 中补齐 from→to 的分步迁移。
//

import Foundation

/// 本地持久化 schema 版本管理（启动时、各 Store 初始化之前调用）。
enum DataSchema {
    /// 当前代码期望的 schema 版本。改持久化结构时务必 +1 并写迁移。
    static let currentVersion = 1

    static let versionKey = "dataSchema.version"

    /// `migrateIfNeeded` 结果（供单测与日志）。
    enum MigrateResult: Equatable, Sendable {
        /// 已是当前版本，未改写。
        case alreadyCurrent(version: Int)
        /// 无版本标记（新装或首次引入 schema）：写入当前版本，不跑迁移步骤。
        case freshInstall(wrote: Int)
        /// 从较低版本升到当前：已执行迁移钩子并写入新版本。
        case migrated(from: Int, to: Int)
    }

    /// 读取已存储版本；无键时为 `nil`。
    static func storedVersion(defaults: UserDefaults = .standard) -> Int? {
        guard defaults.object(forKey: versionKey) != nil else { return nil }
        return defaults.integer(forKey: versionKey)
    }

    /// 启动入口：按需迁移并对齐版本号。须在 `StatsStore` 等初始化之前调用。
    @discardableResult
    static func migrateIfNeeded(defaults: UserDefaults = .standard) -> MigrateResult {
        if let from = storedVersion(defaults: defaults) {
            if from >= currentVersion {
                return .alreadyCurrent(version: from)
            }
            runMigrations(from: from, to: currentVersion, defaults: defaults)
            defaults.set(currentVersion, forKey: versionKey)
            return .migrated(from: from, to: currentVersion)
        }

        // 首次：现有键布局即 version 1，只需盖章，无需变换数据。
        defaults.set(currentVersion, forKey: versionKey)
        return .freshInstall(wrote: currentVersion)
    }

    /// 分步迁移：依次执行 `from+1 ... to`。
    /// 当前无实质步骤（version 1 为基线）；升到 2 时在 `applyMigrationStep(2, ...)` 写具体逻辑。
    static func runMigrations(from: Int, to: Int, defaults: UserDefaults) {
        guard from < to else { return }
        for step in (from + 1)...to {
            applyMigrationStep(step, defaults: defaults)
        }
    }

    /// - Parameter defaults: 供各升版步骤读写键（version 1 基线未使用）。
    /// - Returns: 是否执行了该步的实质迁移逻辑（基线空步返回 `false`）。
    @discardableResult
    static func applyMigrationStep(_ step: Int, defaults: UserDefaults) -> Bool {
        switch step {
        case 1:
            return false
        default:
            return false
        }
    }
}
