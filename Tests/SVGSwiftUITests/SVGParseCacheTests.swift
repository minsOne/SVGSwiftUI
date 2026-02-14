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
}
