import XCTest
@testable import SVGSwiftUI

final class SVGStyleResolverTests: XCTestCase {
    private let resolver = SVGStyleResolver()

    func testInheritsStyleFromParentGroup() {
        let red = SVGPaint.color(.init(red: 1, green: 0, blue: 0, alpha: 1))
        let groupBase = SVGBaseNode(id: "g", syntheticID: "auto:/0/0", style: .init(fill: red))
        let childBase = SVGBaseNode(id: "p", syntheticID: "auto:/0/0/0")
        let document = SVGDocument(nodes: [
            .group(.init(base: groupBase, children: [
                .path(.init(base: childBase, pathData: "M0 0")),
            ])),
        ])

        let resolved = resolver.resolve(document: document)

        XCTAssertEqual(resolved["g"]?.style.fill, red)
        XCTAssertEqual(resolved["p"]?.style.fill, red)
    }

    func testAppliesMapOverrideOverNodeStyle() {
        let black = SVGPaint.color(.init(red: 0, green: 0, blue: 0, alpha: 1))
        let green = SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1))
        let blue = SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1))

        let pathBase = SVGBaseNode(
            id: "path",
            syntheticID: "auto:/0/0",
            style: .init(fill: black, strokeWidth: 1)
        )
        let document = SVGDocument(nodes: [.path(.init(base: pathBase, pathData: "M0 0"))])
        let config = SVGRenderConfiguration(
            idOverrides: [
                "path": NodeOverride(fill: green, stroke: blue, strokeWidth: 3, opacity: 0.4),
            ]
        )

        let resolved = resolver.resolve(document: document, configuration: config)
        let node = tryUnwrap(resolved["path"])

        XCTAssertEqual(node.style.fill, green)
        XCTAssertEqual(node.style.stroke, blue)
        XCTAssertEqual(node.style.strokeWidth, 3)
        XCTAssertEqual(node.style.opacity, 0.4)
    }

    func testAppliesResolverOverrideOverMapOverride() {
        let green = SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1))
        let red = SVGPaint.color(.init(red: 1, green: 0, blue: 0, alpha: 1))
        let blue = SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1))

        let group = SVGBaseNode(id: "group", syntheticID: "auto:/0/0", style: .init(fill: blue))
        let child = SVGBaseNode(id: "child", syntheticID: "auto:/0/0/0")
        let document = SVGDocument(nodes: [
            .group(.init(base: group, children: [.path(.init(base: child, pathData: "M0 0"))])),
        ])
        let config = SVGRenderConfiguration(
            idOverrides: [
                "child": NodeOverride(fill: green, scale: .init(width: 2, height: 2), offset: .init(x: 1, y: 1)),
            ],
            resolver: { context in
                guard context.id == "child" else { return nil }
                if context.inheritedStyle.fill == blue {
                    return NodeOverride(fill: red, offset: .init(x: 9, y: 9))
                }
                return NodeOverride(fill: green, offset: .init(x: 9, y: 9))
            }
        )

        let resolved = resolver.resolve(document: document, configuration: config)
        let node = tryUnwrap(resolved["child"])

        XCTAssertEqual(node.style.fill, red)
        XCTAssertEqual(node.scale, .init(width: 2, height: 2))
        XCTAssertEqual(node.offset, .init(x: 9, y: 9))
    }

    func testGroupOverrideCascadesToChildren() {
        let green = SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1))
        let groupBase = SVGBaseNode(id: "group", syntheticID: "auto:/0/0")
        let childBase = SVGBaseNode(id: "child", syntheticID: "auto:/0/0/0")
        let document = SVGDocument(nodes: [
            .group(.init(base: groupBase, children: [.path(.init(base: childBase, pathData: "M0 0"))])),
        ])
        let config = SVGRenderConfiguration(
            idOverrides: [
                "group": NodeOverride(fill: green),
            ]
        )

        let resolved = resolver.resolve(document: document, configuration: config)
        XCTAssertEqual(resolved["group"]?.style.fill, green)
        XCTAssertEqual(resolved["child"]?.style.fill, green)
    }

    func testUsesSyntheticIDForOverridesWhenNodeHasNoExplicitID() {
        let blue = SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1))
        let pathBase = SVGBaseNode(id: nil, syntheticID: "auto:/0/0")
        let document = SVGDocument(nodes: [.path(.init(base: pathBase, pathData: "M0 0"))])
        let config = SVGRenderConfiguration(
            idOverrides: [
                "auto:/0/0": NodeOverride(fill: blue),
            ]
        )

        let resolved = resolver.resolve(document: document, configuration: config)
        XCTAssertEqual(resolved["auto:/0/0"]?.style.fill, blue)
    }

    func testResolverContextUsesViewportFromViewBoxWhenSizeMissing() {
        let pathBase = SVGBaseNode(id: "path", syntheticID: "auto:/0/0")
        let document = SVGDocument(
            size: nil,
            viewBox: .init(x: 0, y: 0, width: 120, height: 80),
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))]
        )
        let red = SVGPaint.color(.init(red: 1, green: 0, blue: 0, alpha: 1))
        let config = SVGRenderConfiguration(
            resolver: { context in
                if context.viewport == .init(width: 120, height: 80) {
                    return NodeOverride(fill: red)
                }
                return nil
            }
        )

        let resolved = resolver.resolve(document: document, configuration: config)
        XCTAssertEqual(resolved["path"]?.style.fill, red)
    }

    func testStyleRulesApplyBySelectorAndInheritFromParent() {
        let groupBase = SVGBaseNode(
            id: "group",
            syntheticID: "auto:/0/0",
            style: .init(),
            attributes: ["class": "bg"]
        )
        let childBase = SVGBaseNode(id: "child", syntheticID: "auto:/0/0/0")
        let document = SVGDocument(
            nodes: [
                .group(.init(
                    base: groupBase,
                    children: [.path(.init(base: childBase, pathData: "M0 0"))]
                )),
            ],
            styleRules: [
                SVGStyleRule(selector: .id("group"), declarations: ["fill": "blue"]),
                SVGStyleRule(selector: .class("bg"), declarations: ["stroke": "#00ff00"]),
            ]
        )

        let resolved = resolver.resolve(document: document)
        let group = tryUnwrap(resolved["group"])
        let child = tryUnwrap(resolved["child"])

        XCTAssertEqual(group.style.fill, SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(group.style.stroke, SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(child.style.fill, SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
    }

    func testStyleRulesSpecificityAndSourceOrderAreRespected() {
        let pathBase = SVGBaseNode(
            id: "target",
            syntheticID: "auto:/0/0",
            attributes: ["class": "highlight"]
        )
        let document = SVGDocument(
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))],
            styleRules: [
                SVGStyleRule(selector: .class("highlight"), declarations: ["fill": "red"]),
                SVGStyleRule(selector: .element("path"), declarations: ["fill": "blue"]),
                SVGStyleRule(selector: .id("target"), declarations: ["fill": "green"]),
                SVGStyleRule(selector: .class("highlight"), declarations: ["fill": "#ffffff"]),
            ]
        )

        let resolved = resolver.resolve(document: document)
        let node = tryUnwrap(resolved["target"])

        XCTAssertEqual(node.style.fill, SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
    }

    func testStyleRulesWithSameSpecificityUseSourceOrder() {
        let pathBase = SVGBaseNode(
            id: "target",
            syntheticID: "auto:/0/0",
            attributes: ["class": "highlight"]
        )
        let document = SVGDocument(
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))],
            styleRules: [
                SVGStyleRule(selector: .class("highlight"), declarations: ["fill": "red"]),
                SVGStyleRule(selector: .class("highlight"), declarations: ["fill": "#ffffff"]),
            ]
        )

        let resolved = resolver.resolve(document: document)
        let node = tryUnwrap(resolved["target"])
        XCTAssertEqual(node.style.fill, SVGPaint.color(.init(red: 1, green: 1, blue: 1, alpha: 1)))
    }

    func testNodeStyleOverridesStylesheetRules() {
        let pathBase = SVGBaseNode(
            id: "styled-path",
            syntheticID: "auto:/0/0",
            style: .init(fill: SVGPaint.color(.init(red: 1, green: 0, blue: 0, alpha: 1)))
        )
        let document = SVGDocument(
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))],
            styleRules: [SVGStyleRule(selector: .any, declarations: ["fill": "#00ff00"])]
        )

        let resolved = resolver.resolve(document: document)
        let node = tryUnwrap(resolved["styled-path"])
        XCTAssertEqual(node.style.fill, SVGPaint.color(.init(red: 1, green: 0, blue: 0, alpha: 1)))
    }

    func testAppliesStrokeCapJoinStyleDeclarations() {
        let pathBase = SVGBaseNode(id: "styled-path", syntheticID: "auto:/0/0")
        let document = SVGDocument(
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))],
            styleRules: [
                SVGStyleRule(
                    selector: .id("styled-path"),
                    declarations: [
                        "stroke-linecap": "square",
                        "stroke-linejoin": "round",
                    ]
                ),
            ]
        )

        let resolved = resolver.resolve(document: document)
        let node = tryUnwrap(resolved["styled-path"])

        XCTAssertEqual(node.style.strokeLineCap, .square)
        XCTAssertEqual(node.style.strokeLineJoin, .round)
    }

    func testAppliesFillRuleAndDashStylesInResolver() {
        let pathBase = SVGBaseNode(id: "styled-path", syntheticID: "auto:/0/0")
        let document = SVGDocument(
            nodes: [.path(.init(base: pathBase, pathData: "M0 0"))],
            styleRules: [
                SVGStyleRule(
                    selector: .id("styled-path"),
                    declarations: [
                        "fill-rule": "evenodd",
                        "stroke-miterlimit": "7",
                        "stroke-dasharray": "2 4 6",
                        "stroke-dashoffset": "1",
                    ]
                ),
            ]
        )

        let resolved = resolver.resolve(document: document)
        let node = tryUnwrap(resolved["styled-path"])

        XCTAssertEqual(node.style.fillRule, .evenOdd)
        XCTAssertEqual(node.style.strokeMiterLimit, 7)
        XCTAssertEqual(node.style.strokeDashArray, [2, 4, 6])
        XCTAssertEqual(node.style.strokeDashOffset, 1)
    }

    private func tryUnwrap(_ value: SVGResolvedNodeStyle?) -> SVGResolvedNodeStyle {
        guard let value else {
            XCTFail("Expected resolved node")
            return .init(nodeID: "invalid", element: .path, style: .init())
        }
        return value
    }
}
