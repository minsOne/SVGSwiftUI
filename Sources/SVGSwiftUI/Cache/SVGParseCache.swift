import Foundation

struct SVGParseCacheKey: Hashable, Sendable {
    var sourceHash: String
    var options: SVGParserOptions
    var schemaVersion: Int

    init(sourceHash: String, options: SVGParserOptions, schemaVersion: Int = 1) {
        self.sourceHash = sourceHash
        self.options = options
        self.schemaVersion = schemaVersion
    }

    static func from(sourceData: Data, options: SVGParserOptions, schemaVersion: Int? = nil) -> Self {
        let version = schemaVersion ?? options.parserSchemaVersion
        return .init(
            sourceHash: stableHash(for: sourceData),
            options: options,
            schemaVersion: version
        )
    }

    private static func stableHash(for data: Data) -> String {
        var hash: UInt64 = 1469598103934665603
        for byte in data {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return "\(data.count)-" + String(hash, radix: 16)
    }
}

actor SVGParseCache {
    private struct Entry {
        var document: SVGDocument
        var cost: Int
    }

    private var entries: [SVGParseCacheKey: Entry] = [:]
    private var order: [SVGParseCacheKey] = []
    private let maxCost: Int
    private let maxEntries: Int
    private var totalCost: Int = 0

    init(maxCost: Int = 10_000_000, maxEntries: Int = 256) {
        self.maxCost = maxCost
        self.maxEntries = maxEntries
    }

    func document(for key: SVGParseCacheKey) -> SVGDocument? {
        guard let entry = entries[key] else {
            return nil
        }
        touch(key)
        return entry.document
    }

    func insert(_ document: SVGDocument, for key: SVGParseCacheKey, cost: Int) {
        let normalizedCost = max(0, cost)
        if let existing = entries[key] {
            totalCost -= existing.cost
        }
        entries[key] = Entry(document: document, cost: normalizedCost)
        totalCost += normalizedCost
        touch(key)
        evictIfNeeded()
    }

    func removeAll() {
        entries.removeAll()
        order.removeAll()
        totalCost = 0
    }

    var count: Int {
        entries.count
    }

    var currentCost: Int {
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
