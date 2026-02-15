import Foundation

struct SVGDataURIPayload: Sendable, Equatable {
    let mediaType: String
    let data: Data
    let isBase64: Bool

    init(mediaType: String, data: Data, isBase64: Bool) {
        self.mediaType = mediaType
        self.data = data
        self.isBase64 = isBase64
    }
}

enum SVGDataURIParserError: Error, Sendable, Equatable {
    case invalidPrefix
    case missingDataSection
    case invalidBase64
    case invalidPercentEncoding
    case payloadTooLarge(limit: Int, actual: Int)
}

struct SVGDataURIParser: Sendable {
    private enum Constants {
        static let prefix: String = "data:"
        static let defaultMediaType: String = "text/plain;charset=US-ASCII"
    }

    func parse(_ uri: String, maxBytes: Int) throws -> SVGDataURIPayload {
        guard uri.hasPrefix(Constants.prefix) else {
            throw SVGDataURIParserError.invalidPrefix
        }

        let startIndex = uri.index(uri.startIndex, offsetBy: Constants.prefix.count)
        let body = String(uri[startIndex..<uri.endIndex])

        guard let commaIndex = body.firstIndex(of: ",") else {
            throw SVGDataURIParserError.missingDataSection
        }

        let metadata = String(body[..<commaIndex])
        let dataStart = body.index(after: commaIndex)
        let encodedData = String(body[dataStart..<body.endIndex])

        let metadataItems = metadata.split(separator: ";", omittingEmptySubsequences: false)
        let isBase64 = metadataItems.contains(where: { $0.lowercased() == "base64" })

        var mediaType = Constants.defaultMediaType
        if let firstItem = metadataItems.first {
            if firstItem.contains("/") {
                mediaType = String(firstItem)
            } else if firstItem.lowercased() == "base64" {
                mediaType = Constants.defaultMediaType
            }
        }

        let outputData: Data
        if isBase64 {
            guard let decoded = Data(base64Encoded: encodedData, options: [.ignoreUnknownCharacters]) else {
                throw SVGDataURIParserError.invalidBase64
            }
            outputData = decoded
        } else {
            guard let decodedText = encodedData.removingPercentEncoding else {
                throw SVGDataURIParserError.invalidPercentEncoding
            }
            guard let utf8 = decodedText.data(using: .utf8) else {
                throw SVGDataURIParserError.invalidPercentEncoding
            }
            outputData = utf8
        }

        let actualBytes = outputData.count
        guard actualBytes <= maxBytes else {
            throw SVGDataURIParserError.payloadTooLarge(limit: maxBytes, actual: actualBytes)
        }

        return SVGDataURIPayload(mediaType: mediaType, data: outputData, isBase64: isBase64)
    }
}
