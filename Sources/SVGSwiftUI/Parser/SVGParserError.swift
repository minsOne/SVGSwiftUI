import Foundation

enum SVGParserError: Error, Sendable, Equatable {
    case emptyInput
    case invalidUTF8Input
    case invalidSVGRoot
    case malformedDocument(reason: String)
    case notImplemented(reason: String)
}

extension SVGParserError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "empty SVG input."
        case .invalidUTF8Input:
            return "invalid UTF-8 encoding."
        case .invalidSVGRoot:
            return "no valid <svg> root element found."
        case .malformedDocument(let reason):
            return reason.isEmpty ? "malformed SVG document." : reason
        case .notImplemented(let reason):
            return "not implemented: \(reason)"
        }
    }
}
