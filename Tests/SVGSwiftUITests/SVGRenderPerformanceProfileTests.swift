import CoreGraphics
import Foundation
import XCTest

@testable import SVGSwiftUI

final class SVGRenderPerformanceProfileTests: XCTestCase {
    func testRenderProfileAtCacheEnabledBoundary() throws {
        let scenario: RenderProfileScenario = .init(
            nodeCount: 2_000,
            targetByteCount: 300_000,
            shouldCacheDrawNodes: true,
            shouldCachePathCache: true
        )
        try runProfileScenario(scenario)
    }

    func testRenderProfileWhenNodeThresholdExceeded() throws {
        let scenario: RenderProfileScenario = .init(
            nodeCount: 2_001,
            targetByteCount: 300_000,
            shouldCacheDrawNodes: false,
            shouldCachePathCache: false
        )
        try runProfileScenario(scenario)
    }

    func testRenderProfileWhenSourceSizeThresholdExceeded() throws {
        let scenario: RenderProfileScenario = .init(
            nodeCount: 2_000,
            targetByteCount: 300_001,
            shouldCacheDrawNodes: false,
            shouldCachePathCache: false
        )
        try runProfileScenario(scenario)
    }

    private func runProfileScenario(_ scenario: RenderProfileScenario) throws {
        let svgSource: String = largeRectSVG(
            nodeCount: scenario.nodeCount,
            targetByteCount: scenario.targetByteCount
        )
        let sourceData: Data = Data(svgSource.utf8)
        let sourceByteCount: Int = sourceData.count
        let parser: SVGParser = SVGParser()
        let document: SVGDocument = try parser.parse(data: sourceData)
        let decision: SVGRenderCachePolicy.Decision = SVGRenderCachePolicy.decision(
            for: document,
            sourceByteCount: sourceByteCount
        )

        XCTAssertEqual(
            decision.shouldCacheDrawNodes,
            scenario.shouldCacheDrawNodes
        )
        XCTAssertEqual(
            decision.shouldCachePathCache,
            scenario.shouldCachePathCache
        )

        let pathBuilder: SVGNodePathBuilder = SVGNodePathBuilder()
        let transformBuilder: SVGTransformBuilder = SVGTransformBuilder()
        let initialPathCache: [String: CGPath] = decision.shouldCachePathCache
            ? buildPathCache(
                from: document.nodes,
                inheritedTransform: .identity,
                nodePathBuilder: pathBuilder,
                transformBuilder: transformBuilder
            )
            : [:]
        let initialPathCount: Int = renderPathCount(
            from: document.nodes,
            inheritedTransform: .identity,
            nodePathBuilder: pathBuilder,
            transformBuilder: transformBuilder,
            pathCache: initialPathCache,
            canUsePathCache: decision.shouldCachePathCache
        )
        XCTAssertGreaterThan(initialPathCount, 0)

        var measuredPathCount: Int = 0
        measure {
            let measurementParser: SVGParser = SVGParser()
            let measuredDocument: SVGDocument = try! measurementParser.parse(
                data: sourceData
            )
            let measuredDecision: SVGRenderCachePolicy.Decision = SVGRenderCachePolicy.decision(
                for: measuredDocument,
                sourceByteCount: sourceByteCount
            )
            let measuredPathCache: [String: CGPath] = measuredDecision.shouldCachePathCache
                ? buildPathCache(
                    from: measuredDocument.nodes,
                    inheritedTransform: .identity,
                    nodePathBuilder: pathBuilder,
                    transformBuilder: transformBuilder
                )
                : [:]
            let pathCount: Int = renderPathCount(
                from: measuredDocument.nodes,
                inheritedTransform: .identity,
                nodePathBuilder: pathBuilder,
                transformBuilder: transformBuilder,
                pathCache: measuredPathCache,
                canUsePathCache: measuredDecision.shouldCachePathCache
            )
            measuredPathCount += pathCount
        }
        XCTAssertEqual(measuredPathCount > 0, true)
    }
}

private struct RenderProfileScenario {
    let nodeCount: Int
    let targetByteCount: Int
    let shouldCacheDrawNodes: Bool
    let shouldCachePathCache: Bool
}

private func largeRectSVG(nodeCount: Int, targetByteCount: Int) -> String {
    let openTag: String = "<svg xmlns=\"http://www.w3.org/2000/svg\">"
    let closeTag: String = "</svg>"
    let rectTemplate: String = "<rect width=\"1\" height=\"1\"/>"
    let nodes: String = String(repeating: rectTemplate, count: nodeCount)
    let withoutPadding: String = "\(openTag)\(nodes)\(closeTag)"
    let baseByteCount: Int = withoutPadding.utf8.count
    if targetByteCount <= baseByteCount {
        return withoutPadding
    }

    let paddingByteCount: Int = targetByteCount - baseByteCount
    let padding: String = String(repeating: " ", count: paddingByteCount)
    return "\(openTag)\(padding)\(nodes)\(closeTag)"
}

private func buildPathCache(
    from nodes: [SVGNode],
    inheritedTransform: CGAffineTransform,
    nodePathBuilder: SVGNodePathBuilder,
    transformBuilder: SVGTransformBuilder
) -> [String: CGPath] {
    var cache: [String: CGPath] = [:]
    collectPathCache(
        from: nodes,
        inheritedTransform: inheritedTransform,
        nodePathBuilder: nodePathBuilder,
        transformBuilder: transformBuilder,
        pathCache: &cache
    )
    return cache
}

private func collectPathCache(
    from nodes: [SVGNode],
    inheritedTransform: CGAffineTransform,
    nodePathBuilder: SVGNodePathBuilder,
    transformBuilder: SVGTransformBuilder,
    pathCache: inout [String: CGPath]
) {
    for node in nodes {
        switch node {
        case .group(let groupNode):
            let nextTransform: CGAffineTransform = transformBuilder.concatenate(
                local: groupNode.base.transform,
                inherited: inheritedTransform
            )
            collectPathCache(
                from: groupNode.children,
                inheritedTransform: nextTransform,
                nodePathBuilder: nodePathBuilder,
                transformBuilder: transformBuilder,
                pathCache: &pathCache
            )
        case .path, .shape:
            let nodeID: String = node.nodeID
            let path: CGPath? = nodePathBuilder.buildPath(
                for: node,
                inheritedTransform: inheritedTransform
            )
            if let path {
                pathCache[nodeID] = path
            }
        case .rasterImage:
            continue
        }
    }
}

private func renderPathCount(
    from nodes: [SVGNode],
    inheritedTransform: CGAffineTransform,
    nodePathBuilder: SVGNodePathBuilder,
    transformBuilder: SVGTransformBuilder,
    pathCache: [String: CGPath],
    canUsePathCache: Bool
) -> Int {
    var outputPathCount: Int = 0

    for node in nodes {
        switch node {
        case .group(let groupNode):
            let nextTransform: CGAffineTransform = transformBuilder.concatenate(
                local: groupNode.base.transform,
                inherited: inheritedTransform
            )
            outputPathCount += renderPathCount(
                from: groupNode.children,
                inheritedTransform: nextTransform,
                nodePathBuilder: nodePathBuilder,
                transformBuilder: transformBuilder,
                pathCache: pathCache,
                canUsePathCache: canUsePathCache
            )
        case .path, .shape, .rasterImage:
            let path: CGPath? = canUsePathCache
                ? pathCache[node.nodeID]
                : nodePathBuilder.buildPath(
                    for: node,
                    inheritedTransform: inheritedTransform
                )
            if path != nil {
                outputPathCount += 1
            }
        }
    }
    return outputPathCount
}
