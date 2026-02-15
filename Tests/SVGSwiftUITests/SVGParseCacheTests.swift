import XCTest
@testable import SVGSwiftUI

final class SVGParseCacheTests: XCTestCase {
    func testCacheKeyFromSourceDataIncludesSchemaVersion() {
        let data = Data("abc".utf8)
        let options = SVGParserOptions(parserSchemaVersion: 7)
        let key = SVGParseCacheKey.from(sourceData: data, options: options)
        XCTAssertEqual(key.schemaVersion, 7)
    }

    func testCacheKeyFromSourceDataChangesWithSchemaVersion() {
        let data = Data("abc".utf8)
        let options = SVGParserOptions(parserSchemaVersion: 1)
        let keyA = SVGParseCacheKey.from(sourceData: data, options: options, schemaVersion: 1)
        let keyB = SVGParseCacheKey.from(sourceData: data, options: options, schemaVersion: 2)
        XCTAssertNotEqual(keyA, keyB)
    }

    func testCacheKeyFromSourceDataChangesWithOptions() {
        let data = Data("abc".utf8)
        let optionsA = SVGParserOptions(enableStyleTag: true)
        let optionsB = SVGParserOptions(enableStyleTag: false)

        let keyA = SVGParseCacheKey.from(sourceData: data, options: optionsA)
        let keyB = SVGParseCacheKey.from(sourceData: data, options: optionsB)

        XCTAssertNotEqual(keyA, keyB)
    }

    func testCacheStoresAndFetchesDocument() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 5)
        let key = SVGParseCacheKey(sourceHash: "a", options: .init())
        let document = SVGDocument(nodes: [.path(.init(base: .init(syntheticID: "auto:/0"), pathData: "M0 0"))])

        await cache.insert(document, for: key, cost: 10)
        let cached = await cache.document(for: key)

        XCTAssertEqual(cached, document)
    }

    func testCacheEvictsLeastRecentlyUsed() async throws {
        let cache = SVGParseCache(maxCost: 10_000, maxEntries: 1)
        let keyA = SVGParseCacheKey(sourceHash: "a", options: .init())
        let keyB = SVGParseCacheKey(sourceHash: "b", options: .init())

        await cache.insert(.init(nodes: []), for: keyA, cost: 1)
        await cache.insert(.init(nodes: []), for: keyB, cost: 1)

        let a = await cache.document(for: keyA)
        let b = await cache.document(for: keyB)

        XCTAssertNil(a)
        XCTAssertNotNil(b)
    }

    func testCacheEvictsByCostLimit() async throws {
        let cache = SVGParseCache(maxCost: 3, maxEntries: 10)
        let keyA = SVGParseCacheKey(sourceHash: "a", options: .init())
        let keyB = SVGParseCacheKey(sourceHash: "b", options: .init())

        await cache.insert(.init(nodes: []), for: keyA, cost: 2)
        await cache.insert(.init(nodes: []), for: keyB, cost: 2)

        let a = await cache.document(for: keyA)
        let b = await cache.document(for: keyB)
        let cost = await cache.currentCost
        XCTAssertNil(a)
        XCTAssertNotNil(b)
        XCTAssertEqual(cost, 2)
    }

    func testCacheTouchPromotesMostRecentEntry() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 2)
        let keyA = SVGParseCacheKey(sourceHash: "a", options: .init())
        let keyB = SVGParseCacheKey(sourceHash: "b", options: .init())
        let keyC = SVGParseCacheKey(sourceHash: "c", options: .init())

        await cache.insert(.init(nodes: []), for: keyA, cost: 1)
        await cache.insert(.init(nodes: []), for: keyB, cost: 1)
        _ = await cache.document(for: keyA)
        await cache.insert(.init(nodes: []), for: keyC, cost: 1)

        let a = await cache.document(for: keyA)
        let b = await cache.document(for: keyB)
        let c = await cache.document(for: keyC)
        XCTAssertNotNil(a)
        XCTAssertNil(b)
        XCTAssertNotNil(c)
    }

    func testCacheReplacesExistingKeyAndUpdatesCost() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 3)
        let key = SVGParseCacheKey(sourceHash: "same", options: .init())
        let old = SVGDocument(nodes: [.path(.init(base: .init(syntheticID: "auto:/0"), pathData: "M0 0"))])
        let updated = SVGDocument(nodes: [.path(.init(base: .init(syntheticID: "auto:/0"), pathData: "M1 1"))])

        await cache.insert(old, for: key, cost: 7)
        await cache.insert(updated, for: key, cost: 2)

        let count = await cache.count
        let cost = await cache.currentCost
        let document = await cache.document(for: key)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(cost, 2)
        XCTAssertEqual(document, updated)
    }

    func testCacheNegativeCostIsClampedToZero() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 3)
        let key = SVGParseCacheKey(sourceHash: "neg", options: .init())

        await cache.insert(.init(nodes: []), for: key, cost: -10)

        let cost = await cache.currentCost
        let count = await cache.count
        let document = await cache.document(for: key)
        XCTAssertEqual(cost, 0)
        XCTAssertEqual(count, 1)
        XCTAssertNotNil(document)
    }

    func testCacheRemoveAllClearsEntriesAndCost() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 5)
        let keyA = SVGParseCacheKey(sourceHash: "a", options: .init())
        let keyB = SVGParseCacheKey(sourceHash: "b", options: .init())

        await cache.insert(.init(nodes: []), for: keyA, cost: 10)
        await cache.insert(.init(nodes: []), for: keyB, cost: 20)
        await cache.removeAll()

        let count = await cache.count
        let cost = await cache.currentCost
        let a = await cache.document(for: keyA)
        let b = await cache.document(for: keyB)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(cost, 0)
        XCTAssertNil(a)
        XCTAssertNil(b)
    }

    func testCacheMetricsSnapshotTracksHitAndMiss() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 5)
        let hitKey = SVGParseCacheKey(sourceHash: "hit", options: .init())
        let missKey = SVGParseCacheKey(sourceHash: "miss", options: .init())
        await cache.insert(.init(nodes: []), for: hitKey, cost: 8)

        _ = await cache.document(for: hitKey)
        _ = await cache.document(for: missKey)
        let metrics = await cache.metricsSnapshot()

        XCTAssertEqual(metrics.requests, 2)
        XCTAssertEqual(metrics.hits, 1)
        XCTAssertEqual(metrics.misses, 1)
        XCTAssertEqual(metrics.entries, 1)
        XCTAssertEqual(metrics.totalCost, 8)
    }

    func testCacheMetricsAreResetByRemoveAll() async throws {
        let cache = SVGParseCache(maxCost: 100, maxEntries: 5)
        let key = SVGParseCacheKey(sourceHash: "a", options: .init())
        await cache.insert(.init(nodes: []), for: key, cost: 8)
        _ = await cache.document(for: key)
        _ = await cache.document(for: SVGParseCacheKey(sourceHash: "b", options: .init()))

        await cache.removeAll()
        let metrics = await cache.metricsSnapshot()

        XCTAssertEqual(metrics.requests, 0)
        XCTAssertEqual(metrics.hits, 0)
        XCTAssertEqual(metrics.misses, 0)
        XCTAssertEqual(metrics.entries, 0)
        XCTAssertEqual(metrics.totalCost, 0)
    }
}
