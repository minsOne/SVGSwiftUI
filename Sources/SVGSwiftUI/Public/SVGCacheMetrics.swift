public struct SVGCacheMetrics: Sendable, Equatable {
    public var requests: Int
    public var hits: Int
    public var misses: Int
    public var entries: Int
    public var totalCost: Int

    public init(
        requests: Int = 0,
        hits: Int = 0,
        misses: Int = 0,
        entries: Int = 0,
        totalCost: Int = 0
    ) {
        self.requests = requests
        self.hits = hits
        self.misses = misses
        self.entries = entries
        self.totalCost = totalCost
    }

    public var hitRate: Double {
        guard requests > 0 else {
            return 0.0
        }
        let hitsDouble = Double(hits)
        let requestsDouble = Double(requests)
        return hitsDouble / requestsDouble
    }
}
