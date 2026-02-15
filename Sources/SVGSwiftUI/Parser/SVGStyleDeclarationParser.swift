import Foundation

struct SVGStyleDeclarationParser {
    func parse(_ style: String) -> [String: String] {
        var output: [String: String] = [:]

        let declarations = style.split(whereSeparator: { $0 == "\n" })
        for declaration in declarations {
            let declarationParts = declaration.split(separator: ";")
            for rawPair in declarationParts {
                let pair = rawPair.split(separator: ":", maxSplits: 1).map(String.init)
                guard pair.count == 2 else {
                    continue
                }

                let rawKey = pair[0]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let rawValue = pair[1]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !rawKey.isEmpty else {
                    continue
                }
                let cleanValue = removeImportantSuffix(rawValue)
                output[rawKey] = cleanValue
            }
        }

        return output
    }

    private func removeImportantSuffix(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.lowercased().hasSuffix("!important") else {
            return trimmedValue
        }

        let marker = trimmedValue.dropLast(10)
        return marker.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
