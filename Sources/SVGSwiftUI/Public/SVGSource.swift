import Foundation

public enum SVGSource: Sendable, Equatable {
    case string(String)
    case data(Data)
    case fileURL(URL)
}

extension SVGSource {
    func loadData() throws -> Data {
        switch self {
        case .string(let value):
            guard let data = value.data(using: .utf8) else {
                throw SVGParserError.invalidUTF8Input
            }
            return data
        case .data(let data):
            return data
        case .fileURL(let fileURL):
            return try Data(contentsOf: fileURL)
        }
    }
}
