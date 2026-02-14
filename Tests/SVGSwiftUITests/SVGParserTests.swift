import XCTest
@testable import SVGSwiftUI

final class SVGParserTests: XCTestCase {
    func testParseRejectsEmptyInput() {
        let parser = SVGParser()

        XCTAssertThrowsError(try parser.parse(source: .string(""))) { error in
            XCTAssertEqual(error as? SVGParserError, .emptyInput)
        }
    }

    func testParseRejectsNonSVGRoot() {
        let parser = SVGParser()

        XCTAssertThrowsError(try parser.parse(source: .string("<html></html>"))) { error in
            XCTAssertEqual(error as? SVGParserError, .invalidSVGRoot)
        }
    }

    func testParseReturnsDocumentShellForValidSVG() throws {
        let parser = SVGParser()
        let document = try parser.parse(source: .string("<svg width='24' height='24'></svg>"))

        XCTAssertEqual(document.nodes.count, 0)
    }
}
