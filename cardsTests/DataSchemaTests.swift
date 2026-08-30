//
//  DataSchemaTests.swift
//  cardsTests
//
//  A2：持久化 schema 版本迁移单测。
//

import Foundation
import Testing
@testable import cards

struct DataSchemaTests {

    /// 首启：无版本键 → 写入 currentVersion，不走升级迁移。
    @Test func freshInstallWritesCurrentVersion() {
        let defaults = makeDefaults()
        #expect(DataSchema.storedVersion(defaults: defaults) == nil)

        let result = DataSchema.migrateIfNeeded(defaults: defaults)
        #expect(result == .freshInstall(wrote: DataSchema.currentVersion))
        #expect(DataSchema.storedVersion(defaults: defaults) == DataSchema.currentVersion)
    }

    /// 已是当前版本 → alreadyCurrent，版本号保持不变。
    @Test func alreadyCurrentDoesNotChangeStoredVersion() {
        let defaults = makeDefaults()
        defaults.set(DataSchema.currentVersion, forKey: DataSchema.versionKey)

        #expect(DataSchema.migrateIfNeeded(defaults: defaults) == .alreadyCurrent(version: DataSchema.currentVersion))
        #expect(DataSchema.migrateIfNeeded(defaults: defaults) == .alreadyCurrent(version: DataSchema.currentVersion))
        #expect(DataSchema.storedVersion(defaults: defaults) == DataSchema.currentVersion)
    }

    /// 低版本 → 跑迁移钩子并升到 currentVersion；再次调用不再迁移。
    @Test func lowVersionRunsMigrationHookAndBumpsVersion() {
        let defaults = makeDefaults()
        defaults.set(0, forKey: DataSchema.versionKey)

        // 钩子：from 0→1 时 step 1 可被单独调用（基线空步返回 false）。
        #expect(DataSchema.applyMigrationStep(1, defaults: defaults) == false)

        let result = DataSchema.migrateIfNeeded(defaults: defaults)
        #expect(result == .migrated(from: 0, to: DataSchema.currentVersion))
        #expect(DataSchema.storedVersion(defaults: defaults) == DataSchema.currentVersion)
        #expect(DataSchema.migrateIfNeeded(defaults: defaults) == .alreadyCurrent(version: DataSchema.currentVersion))
    }

    /// runMigrations 在 from < to 时按步执行且不崩溃。
    @Test func runMigrationsFromZeroToCurrentIsSafe() {
        let defaults = makeDefaults()
        DataSchema.runMigrations(from: 0, to: DataSchema.currentVersion, defaults: defaults)
        // 迁移步骤不负责写版本号；由 migrateIfNeeded 写入。
        #expect(DataSchema.storedVersion(defaults: defaults) == nil)
        #expect(DataSchema.migrateIfNeeded(defaults: defaults) == .freshInstall(wrote: DataSchema.currentVersion))
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "cards.tests.dataSchema.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
