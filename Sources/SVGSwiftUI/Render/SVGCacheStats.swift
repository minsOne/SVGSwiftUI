#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class SVGCacheStats: ObservableObject {
    @Published public private(set) var metrics: SVGCacheMetrics

    public init(metrics: SVGCacheMetrics = .init()) {
        self.metrics = metrics
    }

    func update(_ metrics: SVGCacheMetrics) {
        self.metrics = metrics
    }
}
#endif
