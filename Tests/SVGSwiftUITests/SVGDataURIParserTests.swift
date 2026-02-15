import XCTest
@testable import SVGSwiftUI

final class SVGDataURIParserTests: XCTestCase {
    private let parser = SVGParser()

    func testParseDataURIBase64DecodesSVGPayload() throws {
        let xml = "<svg xmlns='http://www.w3.org/2000/svg'><path d='M0 0 L10 10'/></svg>"
        let encoded = Data(xml.utf8).base64EncodedString()
        let uri = "data:image/svg+xml;base64,\(encoded)"

        let payload = try parser.parseDataURI(
            uri,
            options: SVGParserOptions(enableDataURI: true, maxDataURIBytes: 1024)
        )

        XCTAssertEqual(payload.mediaType, "image/svg+xml")
        XCTAssertTrue(payload.isBase64)
        XCTAssertEqual(String(data: payload.data, encoding: .utf8), xml)
    }

    func testParseDataURIPercentEncodedText() throws {
        let uri = "data:text/plain,Hello%20World%21"
        let payload = try parser.parseDataURI(
            uri,
            options: SVGParserOptions(enableDataURI: true, maxDataURIBytes: 64)
        )

        XCTAssertEqual(payload.mediaType, "text/plain")
        XCTAssertFalse(payload.isBase64)
        XCTAssertEqual(String(data: payload.data, encoding: .utf8), "Hello World!")
    }

    func testParseDataURIDefaultMediaTypeWhenNotProvided() throws {
        let payload = try parser.parseDataURI(
            "data:,A",
            options: SVGParserOptions(enableDataURI: true)
        )

        XCTAssertEqual(payload.mediaType, "text/plain;charset=US-ASCII")
        XCTAssertEqual(String(data: payload.data, encoding: .utf8), "A")
    }

    func testParseDataURIWithoutOptionsIsRejected() {
        XCTAssertThrowsError(
            try parser.parseDataURI(
                "data:text/plain,ok",
                options: SVGParserOptions(enableDataURI: false)
            )
        ) { error in
            guard let parserError = error as? SVGParserError else {
                return XCTFail("Expected notImplemented error, got \(error)")
            }
            guard case .notImplemented = parserError else {
                return XCTFail("Expected notImplemented error, got \(error)")
            }
        }
    }

    func testParseDataURIMissingPrefixThrowsError() {
        XCTAssertThrowsError(
            try parser.parseDataURI(
                "http://example.com/icon.png",
                options: SVGParserOptions(enableDataURI: true)
            )
        ) { error in
            guard let parserError = error as? SVGDataURIParserError else {
                return XCTFail("Expected SVGDataURIParserError, got \(error)")
            }
            XCTAssertEqual(parserError, .invalidPrefix)
        }
    }

    func testParseDataURIMissingCommaThrowsError() {
        XCTAssertThrowsError(
            try parser.parseDataURI(
                "data:image/svg+xml;base64",
                options: SVGParserOptions(enableDataURI: true)
            )
        ) { error in
            guard let parserError = error as? SVGDataURIParserError else {
                return XCTFail("Expected SVGDataURIParserError, got \(error)")
            }
            XCTAssertEqual(parserError, .missingDataSection)
        }
    }

    func testParseDataURIInvalidBase64ThrowsError() {
        XCTAssertThrowsError(
            try parser.parseDataURI(
                "data:image/svg+xml;base64,not-valid-base64$$",
                options: SVGParserOptions(enableDataURI: true)
            )
        ) { error in
            guard let parserError = error as? SVGDataURIParserError else {
                return XCTFail("Expected SVGDataURIParserError, got \(error)")
            }
            XCTAssertEqual(parserError, .invalidBase64)
        }
    }

    func testParseDataURIPayloadTooLargeThrowsError() {
        let source = String(repeating: "a", count: 100)
        let encoded = Data(source.utf8).base64EncodedString()
        let uri = "data:text/plain;base64,\(encoded)"

        XCTAssertThrowsError(
            try parser.parseDataURI(
                uri,
                options: SVGParserOptions(enableDataURI: true, maxDataURIBytes: 32)
            )
        ) { error in
            guard let parserError = error as? SVGDataURIParserError else {
                return XCTFail("Expected SVGDataURIParserError, got \(error)")
            }
            XCTAssertEqual(parserError, .payloadTooLarge(limit: 32, actual: 100))
        }
    }

    func testParseDataURIDisabledWhenMaxSizeIsZero() {
        XCTAssertThrowsError(
            try parser.parseDataURI(
                "data:text/plain,ok",
                options: SVGParserOptions(enableDataURI: true, maxDataURIBytes: 0)
            )
        ) { error in
            guard let parserError = error as? SVGParserError else {
                return XCTFail("Expected SVGParserError, got \(error)")
            }
            guard case .notImplemented = parserError else {
                return XCTFail("Expected notImplemented error, got \(error)")
            }
        }
    }
}
