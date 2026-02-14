import Foundation

enum SVGParserError: Error, Sendable, Equatable {
    case emptyInput
    case invalidUTF8Input
    case invalidSVGRoot
    case malformedDocument(reason: String)
    case notImplemented(reason: String)
}
