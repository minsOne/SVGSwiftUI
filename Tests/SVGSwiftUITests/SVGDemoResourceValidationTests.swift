import Foundation
import XCTest
@testable import SVGSwiftUI

final class SVGDemoResourceValidationTests: XCTestCase {
    private let parser = SVGParser()
    private let styleAwareParserOptions = SVGParserOptions(enableStyleTag: true)
    private let styleAwareResolver = SVGStyleResolver()
    private let nodePathBuilder = SVGNodePathBuilder()

    private struct ProblematicSampleCase {
        let fileName: String
        let keyNodeID: String
        let minimumRenderedShapeCount: Int
        let expectedUnsupported: [String: Int]
    }

    private let problematicSamples: [ProblematicSampleCase] = [
        .init(
            fileName: "mesh-network.svg",
            keyNodeID: "mesh-bg",
            minimumRenderedShapeCount: 80,
            expectedUnsupported: [:]
        ),
        .init(
            fileName: "spiral-paths.svg",
            keyNodeID: "path-bg",
            minimumRenderedShapeCount: 8,
            expectedUnsupported: [:]
        ),
        .init(
            fileName: "style-sheet.svg",
            keyNodeID: "sheet-circle",
            minimumRenderedShapeCount: 2,
            expectedUnsupported: ["element:text": 1]
        ),
        .init(
            fileName: "orbital-lattice.svg",
            keyNodeID: "lattice-bg",
            minimumRenderedShapeCount: 120,
            expectedUnsupported: [:]
        ),
        .init(
            fileName: "aurora-wave.svg",
            keyNodeID: "aurora-backdrop",
            minimumRenderedShapeCount: 10,
            expectedUnsupported: [:]
        ),
        .init(
            fileName: "dense-grid-world.svg",
            keyNodeID: "grid-bg",
            minimumRenderedShapeCount: 300,
            expectedUnsupported: [:]
        )
    ]

    func testAllDemoResourcesParseSuccessfully() throws {
        let fileManager = FileManager.default
        let resourcesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../..", isDirectory: true)
            .appendingPathComponent("Examples", isDirectory: true)
            .appendingPathComponent("SVGSwiftUIDemo", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .standardized

        guard let sampleURLs = try? fileManager.contentsOfDirectory(
            at: resourcesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return XCTFail("Demo 리소스 디렉터리를 읽을 수 없습니다: \(resourcesURL.path)")
        }

        let svgURLs = sampleURLs
            .filter { $0.pathExtension.lowercased() == "svg" }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

        XCTAssertFalse(
            svgURLs.isEmpty,
            "SVG 파일을 찾을 수 없습니다: \(resourcesURL.path)"
        )

        for svgURL in svgURLs {
            let fileName = svgURL.lastPathComponent
            let data = try Data(contentsOf: svgURL)
            let document = try parser.parse(data: data)
            let styleDocument = try parser.parse(data: data, options: styleAwareParserOptions)
            let sourceText = String(data: data, encoding: .utf8) ?? ""

            XCTAssertEqual(
                document.nodes.isEmpty,
                false,
                "No root drawable nodes in \(fileName)"
            )
            XCTAssertEqual(
                styleDocument.nodes.isEmpty,
                false,
                "No style-enabled drawable nodes in \(fileName)"
            )
            if sourceText.range(of: "<style", options: .caseInsensitive) != nil {
                XCTAssertGreaterThan(
                    styleDocument.styleRules.count,
                    0,
                    "\(fileName) has embedded style block but no style rules were parsed."
                )
            }
        }
    }

    func testProblematicSamplesCanParseAndResolveStylesStep1() throws {
        for sample in problematicSamples {
            let sourceText: String = try resourceSourceText(for: sample.fileName)
            let data = sourceText.data(using: .utf8) ?? Data()
            let document = try parser.parse(data: data)
            let styleDocument = try parser.parse(
                data: data,
                options: styleAwareParserOptions
            )

            XCTAssertFalse(
                document.nodes.isEmpty,
                "No drawable nodes without style for \(sample.fileName)"
            )
            XCTAssertFalse(
                styleDocument.nodes.isEmpty,
                "No drawable nodes with style for \(sample.fileName)"
            )
            XCTAssertEqual(
                sourceText.isEmpty,
                false,
                "Source text should not be empty: \(sample.fileName)"
            )
        }
    }

    func testProblematicSamplesUnsupportedFeaturesStep2() throws {
        for sample in problematicSamples {
            let sourceText: String = try resourceSourceText(for: sample.fileName)
            let data = sourceText.data(using: .utf8) ?? Data()
            let document = try parser.parse(
                data: data,
                options: styleAwareParserOptions
            )

            XCTAssertEqual(
                document.unsupportedFeatures,
                sample.expectedUnsupported,
                "Unsupported feature map mismatch for \(sample.fileName)"
            )
            if let styleTagRange = sourceText.range(of: "<style", options: .caseInsensitive),
               !styleTagRange.isEmpty {
                XCTAssertGreaterThan(
                    document.styleRules.count,
                    0,
                    "No CSS rules parsed although style tag exists: \(sample.fileName)"
                )
            }
        }
    }

    func testProblematicSamplesRenderableGeometryStep3() throws {
        for sample in problematicSamples {
            let sourceText: String = try resourceSourceText(for: sample.fileName)
            let data = sourceText.data(using: .utf8) ?? Data()
            let document = try parser.parse(
                data: data,
                options: styleAwareParserOptions
            )
            let resolved = styleAwareResolver.resolve(document: document)

            let keyNode = tryUnwrap(
                resolved[sample.keyNodeID],
                "Expected resolved style for key node: \(sample.keyNodeID) in \(sample.fileName)"
            )
            XCTAssertFalse(
                nodePaint(from: keyNode.style) == false,
                "Key node has no visible paint: \(sample.fileName) / \(sample.keyNodeID)"
            )

            let renderedNodeCount = renderedShapeNodeCount(
                in: document.nodes,
                resolved: resolved,
                inheritedTransform: .identity
            )
            XCTAssertGreaterThanOrEqual(
                renderedNodeCount,
                sample.minimumRenderedShapeCount,
                "Rendered node count is too low for \(sample.fileName)"
            )
        }
    }

    func testComplexDemoSamplesHaveResolvedClassStyles() throws {
        let styleSamples: [(fileName: String, nodeID: String, expectedFill: SVGPaint, expectedStroke: SVGPaint, expectedFillOpacity: Double, expectedStrokeOpacity: Double)] = [
            (
                "mesh-network.svg",
                "mesh-bg",
                SVGPaint.color(SVGColor(red: 0.9725490196078431, green: 0.9803921568627451, blue: 0.9882352941176471, alpha: 1.0)),
                SVGPaint.color(SVGColor(red: 0.058823529411764705, green: 0.09019607843137255, blue: 0.16470588235294117, alpha: 1.0)),
                1.0,
                1.0
            ),
            (
                "spiral-paths.svg",
                "path-bg",
                SVGPaint.color(SVGColor(red: 0.9725490196078431, green: 0.9803921568627451, blue: 0.9882352941176471, alpha: 1.0)),
                SVGPaint.color(SVGColor(red: 0.058823529411764705, green: 0.09019607843137255, blue: 0.16470588235294117, alpha: 1.0)),
                1.0,
                1.0
            ),
            (
                "aurora-wave.svg",
                "aurora-backdrop",
                SVGPaint.color(SVGColor(red: 0.00784313725490196, green: 0.023529411764705882, blue: 0.09019607843137255, alpha: 1.0)),
                SVGPaint.color(SVGColor(red: 0.49019607843137253, green: 0.8274509803921568, blue: 0.9882352941176471, alpha: 1.0)),
                1.0,
                1.0
            ),
            (
                "dense-grid-world.svg",
                "grid-bg",
                SVGPaint.color(SVGColor(red: 0.9725490196078431, green: 0.9803921568627451, blue: 0.9882352941176471, alpha: 1.0)),
                SVGPaint.color(SVGColor(red: 0.058823529411764705, green: 0.09019607843137255, blue: 0.16470588235294117, alpha: 1.0)),
                1.0,
                1.0
            ),
            (
                "orbital-lattice.svg",
                "lattice-frame",
                SVGPaint.color(SVGColor(red: 0.00784313725490196, green: 0.023529411764705882, blue: 0.09019607843137255, alpha: 1.0)),
                SVGPaint.none,
                0.04,
                1.0
            )
        ]

        let resourcesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../..", isDirectory: true)
            .appendingPathComponent("Examples", isDirectory: true)
            .appendingPathComponent("SVGSwiftUIDemo", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .standardized

        for sample in styleSamples {
            let resourceName = sample.fileName
            let sampleURL = resourcesURL.appendingPathComponent(resourceName)
            let sourceText = try String(contentsOf: sampleURL, encoding: .utf8)
            let document = try parser.parse(
                data: sourceText.data(using: .utf8) ?? Data(),
                options: styleAwareParserOptions
            )
            let resolved = styleAwareResolver.resolve(document: document)

            let frameNode = tryUnwrap(resolved[sample.nodeID], "Expected resolved style for \(sample.nodeID)")
            XCTAssertEqual(frameNode.style.fill, sample.expectedFill, "Fill mismatch for \(resourceName) / \(sample.nodeID)")
            XCTAssertEqual(frameNode.style.stroke, sample.expectedStroke, "Stroke mismatch for \(resourceName) / \(sample.nodeID)")
            XCTAssertEqual(
                frameNode.style.fillOpacity,
                sample.expectedFillOpacity,
                "Fill-opacity mismatch for \(resourceName) / \(sample.nodeID)"
            )
            XCTAssertEqual(
                frameNode.style.strokeOpacity,
                sample.expectedStrokeOpacity,
                "Stroke-opacity mismatch for \(resourceName) / \(sample.nodeID)"
            )
        }
    }

    private func renderedShapeNodeCount(
        in nodes: [SVGNode],
        resolved: [String: SVGResolvedNodeStyle],
        inheritedTransform: CGAffineTransform
    ) -> Int {
        var total = 0

        for node in nodes {
            if let resolvedStyle = resolved[node.nodeID],
               let path = nodePathBuilder.buildPath(for: node, inheritedTransform: inheritedTransform),
               !path.isEmpty,
               nodePaint(from: resolvedStyle.style)
            {
                total += 1
            }

            if let childTotal = renderChildCount(for: node, resolved: resolved, inheritedTransform: inheritedTransform) {
                total += childTotal
            }
        }
        return total
    }

    private func renderChildCount(
        for node: SVGNode,
        resolved: [String: SVGResolvedNodeStyle],
        inheritedTransform: CGAffineTransform
    ) -> Int? {
        switch node {
        case .group(let group):
            let nextTransform: CGAffineTransform = nodeTransform(
                for: group,
                inherited: inheritedTransform
            )
            let count = renderedShapeNodeCount(
                in: group.children,
                resolved: resolved,
                inheritedTransform: nextTransform
            )
            return count
        case .path, .shape, .rasterImage:
            return 0
        }
    }

    private func nodeTransform(for node: SVGGroupNode, inherited: CGAffineTransform) -> CGAffineTransform {
        let transformBuilder = SVGTransformBuilder()
        return transformBuilder.concatenate(
            local: node.base.transform,
            inherited: inherited
        )
    }

    private func nodePaint(from style: SVGResolvedStyle) -> Bool {
        let fillVisible = style.fill != .none && style.fillOpacity > 0 && style.opacity > 0
        let strokeVisible = style.stroke != .none && style.strokeOpacity > 0 && style.opacity > 0 && style.strokeWidth > 0
        return fillVisible || strokeVisible
    }

    private func resourceURL(for fileName: String) -> URL {
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../..", isDirectory: true)
            .appendingPathComponent("Examples", isDirectory: true)
            .appendingPathComponent("SVGSwiftUIDemo", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
            .standardized
    }

    private func resourceSourceText(for fileName: String) throws -> String {
        let sourceURL = resourceURL(for: fileName)
        return try String(contentsOf: sourceURL, encoding: .utf8)
    }

    private func tryUnwrap<T>(
        _ value: T?,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T {
        guard let value else {
            XCTFail(message, file: file, line: line)
            fatalError("Expected non-nil value")
        }
        return value
    }
}
