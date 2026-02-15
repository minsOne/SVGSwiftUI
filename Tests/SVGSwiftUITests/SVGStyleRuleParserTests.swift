import XCTest
@testable import SVGSwiftUI

final class SVGStyleRuleParserTests: XCTestCase {
    private let parser = SVGStyleRuleParser()

    func testParseIDAndClassSelectors() {
        let rules = parser.parse("""
            #icon { fill: red; stroke: #00f; }
            .muted { opacity: 0.5; }
            path { fill: green; }
        """)

        XCTAssertEqual(rules.count, 3)
        guard case .id("icon") = rules[0].selector else {
            return XCTFail("Expected id selector")
        }
        guard case .class("muted") = rules[1].selector else {
            return XCTFail("Expected class selector")
        }
        guard case .element("path") = rules[2].selector else {
            return XCTFail("Expected element selector")
        }
        XCTAssertEqual(rules[0].declarations["fill"], "red")
        XCTAssertEqual(rules[1].declarations["opacity"], "0.5")
    }

    func testParseCommaSeparatedSelectorsAndComments() {
        let rules = parser.parse("""
            /* comment */
            #icon, .secondary, path {
                fill: #0f0;
                stroke: #00f;
            }
            @media (max-width: 600px) { .ignored { fill: blue; } }
        """)

        XCTAssertEqual(rules.count, 3)
        XCTAssertEqual(rules[0].declarations["fill"], "#0f0")
        XCTAssertEqual(rules[1].declarations["fill"], "#0f0")
        XCTAssertEqual(rules[2].declarations["fill"], "#0f0")
        XCTAssertEqual(rules[0].declarations["stroke"], "#00f")
    }

    func testIgnoreUnsupportedComplexSelector() {
        let rules = parser.parse("div .child { fill:red; }")

        XCTAssertTrue(rules.isEmpty)
    }
}

