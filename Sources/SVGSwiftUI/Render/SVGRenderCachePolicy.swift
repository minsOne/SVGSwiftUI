import Foundation

struct SVGRenderCachePolicy {
    private static let maxDrawableNodeCountForCachedDrawNodes: Int = 2_000
    private static let maxSourceSizeForCachedDrawNodes: Int = 300_000
    private static let maxDrawableNodeCountForCachedPathCache: Int = 2_000
    private static let maxSourceSizeForCachedPathCache: Int = 300_000

    struct Decision {
        let shouldCacheDrawNodes: Bool
        let shouldCachePathCache: Bool
        let drawableNodeCount: Int
        let sourceByteCount: Int
    }

    static func decision(
        for document: SVGDocument,
        sourceByteCount: Int
    ) -> Decision {
        let nodeCount: Int = drawableNodeCount(in: document.nodes)
        let exceedsNodeThreshold: Bool = nodeCount > maxDrawableNodeCountForCachedDrawNodes
        let exceedsSourceThreshold: Bool = sourceByteCount > maxSourceSizeForCachedDrawNodes
        let canCacheDrawNodes: Bool = !exceedsNodeThreshold && !exceedsSourceThreshold

        let exceedsPathNodeThreshold: Bool = nodeCount > maxDrawableNodeCountForCachedPathCache
        let exceedsPathSourceThreshold: Bool = sourceByteCount > maxSourceSizeForCachedPathCache
        let canCachePathCache: Bool = !exceedsPathNodeThreshold && !exceedsPathSourceThreshold

        return Decision(
            shouldCacheDrawNodes: canCacheDrawNodes,
            shouldCachePathCache: canCachePathCache,
            drawableNodeCount: nodeCount,
            sourceByteCount: sourceByteCount
        )
    }

    static func shouldCacheDrawNodes(
        for document: SVGDocument,
        sourceByteCount: Int
    ) -> Bool {
        return decision(for: document, sourceByteCount: sourceByteCount).shouldCacheDrawNodes
    }

    static func shouldCachePathCache(
        for document: SVGDocument,
        sourceByteCount: Int
    ) -> Bool {
        return decision(for: document, sourceByteCount: sourceByteCount).shouldCachePathCache
    }

    static func drawableNodeCount(in nodes: [SVGNode]) -> Int {
        return nodes.reduce(0) { count, node in
            let childCount: Int = drawableNodeCount(for: node)
            return count + childCount
        }
    }

    private static func drawableNodeCount(for node: SVGNode) -> Int {
        switch node {
        case .group(let groupNode):
            return 1 + drawableNodeCount(in: groupNode.children)
        case .path, .shape, .rasterImage:
            return 1
        }
    }
}
