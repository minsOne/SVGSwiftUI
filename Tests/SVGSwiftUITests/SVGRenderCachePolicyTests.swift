import XCTest
@testable import SVGSwiftUI

final class SVGRenderCachePolicyTests: XCTestCase {
    func testDrawableNodeCountCountsAllDrawableNodes() {
        let rootBase: SVGBaseNode = SVGBaseNode(
            id: "group-root",
            syntheticID: "group-root"
        )
        let childBase: SVGBaseNode = SVGBaseNode(
            id: "group-child",
            syntheticID: "group-child"
        )
        let shapeBase: SVGBaseNode = SVGBaseNode(
            id: "shape",
            syntheticID: "shape"
        )
        let pathBase: SVGBaseNode = SVGBaseNode(
            id: "path",
            syntheticID: "path"
        )

        let nodes: [SVGNode] = [
            .group(
                SVGGroupNode(
                    base: rootBase,
                    children: [
                        .shape(
                            SVGShapeNode(
                                base: shapeBase,
                                kind: .rect
                            )
                        ),
                        .group(
                            SVGGroupNode(
                                base: childBase,
                                children: [
                                    .path(
                                        SVGPathNode(
                                            base: pathBase,
                                            pathData: ""
                                        )
                                    )
                                ]
                            )
                        ),
                    ]
                )
            )
        ]

        let drawableCount: Int = SVGRenderCachePolicy.drawableNodeCount(in: nodes)
        XCTAssertEqual(drawableCount, 4)
    }

    func testShouldCacheDrawNodesForSmallDocument() {
        let nodes: [SVGNode] = [
            .path(
                SVGPathNode(
                    base: SVGBaseNode(
                        id: "path",
                        syntheticID: "path"
                    ),
                    pathData: "M0 0 L1 1"
                )
            )
        ]
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCacheDrawNodes(
            for: document,
            sourceByteCount: 1_000
        )

        XCTAssertTrue(canCache)
    }

    func testShouldDisableCacheForLargeSourceSize() {
        let nodes: [SVGNode] = [
            .path(
                SVGPathNode(
                    base: SVGBaseNode(
                        id: "path",
                        syntheticID: "path"
                    ),
                    pathData: "M0 0 L1 1"
                )
            )
        ]
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCacheDrawNodes(
            for: document,
            sourceByteCount: 400_000
        )

        XCTAssertFalse(canCache)
    }

    func testShouldEnableCacheAtThresholds() {
        let nodes: [SVGNode] = Array(
            repeating: SVGNode.shape(
                SVGShapeNode(
                    base: SVGBaseNode(id: "shape", syntheticID: "shape"),
                    kind: .circle
                )
            ),
            count: 2_000
        )
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let canCacheDrawNodes = SVGRenderCachePolicy.shouldCacheDrawNodes(
            for: document,
            sourceByteCount: 300_000
        )
        let canCachePathNodes = SVGRenderCachePolicy.shouldCachePathCache(
            for: document,
            sourceByteCount: 300_000
        )

        XCTAssertTrue(canCacheDrawNodes)
        XCTAssertTrue(canCachePathNodes)
    }

    func testShouldDisableCacheForManyDrawableNodes() {
        let manyNodes: [SVGNode] = buildShapeNodes(count: 2_100)
        let document: SVGDocument = SVGDocument(nodes: manyNodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCacheDrawNodes(
            for: document,
            sourceByteCount: 1_000
        )

        XCTAssertFalse(canCache)
    }

    func testShouldEnablePathCacheForSmallDocument() {
        let nodes: [SVGNode] = [
            .path(
                SVGPathNode(
                    base: SVGBaseNode(
                        id: "path",
                        syntheticID: "path"
                    ),
                    pathData: "M0 0 L1 1"
                )
            )
        ]
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCachePathCache(
            for: document,
            sourceByteCount: 1_000
        )

        XCTAssertTrue(canCache)
    }

    func testShouldDisablePathCacheForManyDrawableNodes() {
        let manyNodes: [SVGNode] = buildShapeNodes(count: 2_100)
        let document: SVGDocument = SVGDocument(nodes: manyNodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCachePathCache(
            for: document,
            sourceByteCount: 1_000
        )

        XCTAssertFalse(canCache)
    }

    func testShouldDisablePathCacheForLargeSourceSize() {
        let nodes: [SVGNode] = [
            .path(
                SVGPathNode(
                    base: SVGBaseNode(
                        id: "path",
                        syntheticID: "path"
                    ),
                    pathData: "M0 0 L1 1"
                )
            )
        ]
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let canCache: Bool = SVGRenderCachePolicy.shouldCachePathCache(
            for: document,
            sourceByteCount: 400_000
        )

        XCTAssertFalse(canCache)
    }

    func testPolicyDecisionCarriesCountsAndPolicies() {
        let nodes: [SVGNode] = buildShapeNodes(count: 2_100)
        let document: SVGDocument = SVGDocument(nodes: nodes)

        let decision: SVGRenderCachePolicy.Decision = SVGRenderCachePolicy.decision(
            for: document,
            sourceByteCount: 400_000
        )

        XCTAssertEqual(decision.drawableNodeCount, 2_100)
        XCTAssertEqual(decision.sourceByteCount, 400_000)
        XCTAssertFalse(decision.shouldCacheDrawNodes)
        XCTAssertFalse(decision.shouldCachePathCache)
    }
}

private func buildShapeNodes(count: Int) -> [SVGNode] {
    var nodes: [SVGNode] = []
    nodes.reserveCapacity(count)

    for index in 0..<count {
        let nodeID = "node-\(index)"
        let base = SVGBaseNode(id: nodeID, syntheticID: nodeID)
        let node = SVGNode.shape(
            SVGShapeNode(
                base: base,
                kind: .circle
            )
        )
        nodes.append(node)
    }
    return nodes
}
