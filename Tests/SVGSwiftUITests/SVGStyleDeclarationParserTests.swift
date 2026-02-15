import XCTest
@testable import SVGSwiftUI

final class SVGStyleDeclarationParserTests: XCTestCase {
    private let parser = SVGStyleDeclarationParser()

    func testParseReturnsTrimmedPropertyAndValuePairs() {
        let declarations = parser.parse("  fill: #00ff00 ; stroke : #0000ff ; stroke-width :2 ; opacity: 0.5 ")

        XCTAssertEqual(declarations["fill"], "#00ff00")
        XCTAssertEqual(declarations["stroke"], "#0000ff")
        XCTAssertEqual(declarations["stroke-width"], "2")
        XCTAssertEqual(declarations["opacity"], "0.5")
    }

    func testParseSupportsNewlinesAndIgnoresInvalidPairs() {
        let declarations = parser.parse("""
            fill:#0f0;
            stroke-width:4
            opacity:0.8;
            malformed
        """)

        XCTAssertEqual(declarations["fill"], "#0f0")
        XCTAssertEqual(declarations["stroke-width"], "4")
        XCTAssertEqual(declarations["opacity"], "0.8")
        XCTAssertNil(declarations["malformed"])
    }

    func testParseDropsImportantSuffixWhenPresent() {
        let declarations = parser.parse("fill: red !important; stroke-width: 2px;")

        XCTAssertEqual(declarations["fill"], "red")
        XCTAssertEqual(declarations["stroke-width"], "2px")
    }
}
