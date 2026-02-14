import XCTest
@testable import SVGSwiftUI

final class SVGParseCacheTests: XCTestCase {
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
}
