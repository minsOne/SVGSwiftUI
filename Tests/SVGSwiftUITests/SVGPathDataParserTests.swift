import XCTest
@testable import SVGSwiftUI

final class SVGPathDataParserTests: XCTestCase {
    private let parser = SVGPathDataParser()

    func testParseBasicMoveLineClose() throws {
        let commands = try parser.parse("M0 0 L10 20 Z")
        XCTAssertEqual(commands, [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "L", values: [10, 20]),
            .init(symbol: "Z", values: []),
        ])
    }

    func testParseRelativeCommandsWithCommaSeparators() throws {
        let commands = try parser.parse("m1,2 l3,4 h5 v6 z")
        XCTAssertEqual(commands, [
            .init(symbol: "m", values: [1, 2]),
            .init(symbol: "l", values: [3, 4]),
            .init(symbol: "h", values: [5]),
            .init(symbol: "v", values: [6]),
            .init(symbol: "z", values: []),
        ])
    }

    func testParseSupportsScientificNotation() throws {
        let commands = try parser.parse("M1e2 -2.5e-1")
        XCTAssertEqual(commands, [
            .init(symbol: "M", values: [100, -0.25]),
        ])
    }

    func testParseSupportsArcCommand() throws {
        let commands = try parser.parse("A10 20 30 0 1 40 50")
        XCTAssertEqual(commands, [
            .init(symbol: "A", values: [10, 20, 30, 0, 1, 40, 50]),
        ])
    }

    func testParseSupportsMultipleSegmentsInSingleCommand() throws {
        let commands = try parser.parse("L0 0 10 10 20 20")
        XCTAssertEqual(commands, [
            .init(symbol: "L", values: [0, 0, 10, 10, 20, 20]),
        ])
    }

    func testParseRejectsMissingCommandPrefix() {
        XCTAssertThrowsError(try parser.parse("10 20")) { error in
            XCTAssertEqual(error as? SVGPathDataParserError, .missingCommand)
        }
    }

    func testParseRejectsUnsupportedCommand() {
        XCTAssertThrowsError(try parser.parse("R 10 10")) { error in
            XCTAssertEqual(error as? SVGPathDataParserError, .unsupportedCommand("R"))
        }
    }

    func testParseRejectsInvalidArityForCurveCommand() {
        XCTAssertThrowsError(try parser.parse("C 10 20 30 40")) { error in
            XCTAssertEqual(error as? SVGPathDataParserError, .invalidParameterCount(command: "C", count: 4))
        }
    }

    func testParseRejectsInvalidArityForCloseCommand() {
        XCTAssertThrowsError(try parser.parse("Z 1")) { error in
            XCTAssertEqual(error as? SVGPathDataParserError, .invalidParameterCount(command: "Z", count: 1))
        }
    }
}
