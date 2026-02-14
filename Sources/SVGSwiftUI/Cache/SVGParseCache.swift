import Foundation

public struct SVGParseCacheKey: Hashable, Sendable {
    public var sourceHash: String
    public var options: SVGParserOptions

    public init(sourceHash: String, options: SVGParserOptions) {
        self.sourceHash = sourceHash
        self.options = options
    }
}

public actor SVGParseCache {
    private struct Entry {
        var document: SVGDocument
        var cost: Int
    }

    private var entries: [SVGParseCacheKey: Entry] = [:]
    private var order: [SVGParseCacheKey] = []
    private let maxCost: Int
    private let maxEntries: Int
    private var totalCost: Int = 0

    public init(maxCost: Int = 10_000_000, maxEntries: Int = 256) {
        self.maxCost = maxCost
        self.maxEntries = maxEntries
    }

    public func document(for key: SVGParseCacheKey) -> SVGDocument? {
        guard let entry = entries[key] else {
            return nil
        }
        touch(key)
        return entry.document
    }

    public func insert(_ document: SVGDocument, for key: SVGParseCacheKey, cost: Int) {
        if let existing = entries[key] {
            totalCost -= existing.cost
        }
        entries[key] = Entry(document: document, cost: cost)
        totalCost += max(0, cost)
        touch(key)
        evictIfNeeded()
    }

    public func removeAll() {
        entries.removeAll()
        order.removeAll()
        totalCost = 0
    }

    public var count: Int {
        entries.count
    }

    public var currentCost: Int {
        totalCost
    }

    private func touch(_ key: SVGParseCacheKey) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.insert(key, at: 0)
    }

    private func evictIfNeeded() {
        while entries.count > maxEntries || totalCost > maxCost {
            guard let last = order.last else {
                break
            }
            order.removeLast()
            if let removed = entries.removeValue(forKey: last) {
                totalCost -= removed.cost
            }
        }
    }
}
