import Foundation

struct SVGParsedKeyframe {
    let offset: Double
    let declarations: [String: String]
}

struct SVGParsedKeyframeDefinition {
    let name: String
    let frames: [SVGParsedKeyframe]
}

struct SVGParsedAnimationDescriptor {
    let name: String
    let duration: String?
    let delay: String?
    let timingFunction: String?
    let iterationCount: String?
    let fillMode: String?
    let direction: String?
}

struct SVGKeyframeParser {
    private let declarationParser = SVGStyleDeclarationParser()

    func parse(_ styleText: String) -> [SVGParsedKeyframeDefinition] {
        let cleanedText: String = stripComments(styleText)
        let characters: [Character] = Array(cleanedText)
        var cursor: Int = 0
        var output: [SVGParsedKeyframeDefinition] = []
        let keywordPatterns: [[Character]] = [
            Array("@keyframes"),
            Array("@-webkit-keyframes"),
        ]

        while true {
            let keywordStart: Int? = nextKeywordStart(
                in: characters,
                from: cursor,
                keywords: keywordPatterns
            )
            guard let currentStart = keywordStart else {
                break
            }

            let keywordLength = keywordLength(at: currentStart, in: characters, keywords: keywordPatterns)
            guard let keywordLength else {
                cursor = currentStart + 1
                continue
            }

            var nameCursor = currentStart + keywordLength
            nameCursor = skipWhitespace(characters, from: nameCursor)
            if nameCursor >= characters.count {
                break
            }

            var nameEnd = nameCursor
            while nameEnd < characters.count {
                let character = characters[nameEnd]
                if character.isWhitespace || character == "{" {
                    break
                }
                nameEnd += 1
            }

            let rawName: String = String(characters[nameCursor..<nameEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if rawName.isEmpty {
                cursor = nameEnd
                continue
            }

            guard let openBraceIndex = index(of: "{", from: nameEnd, in: characters) else {
                break
            }

            guard let closeBraceIndex = matchingBraceEnd(
                openBraceIndex: openBraceIndex,
                characters: characters
            ) else {
                break
            }

            let bodyRange = (openBraceIndex + 1)..<closeBraceIndex
            let bodyText: String = String(characters[bodyRange])
            let frames = parseFrames(from: bodyText)
            if !frames.isEmpty {
                output.append(SVGParsedKeyframeDefinition(name: rawName.lowercased(), frames: frames))
            }

            cursor = closeBraceIndex + 1
        }

        return output
    }

    private func nextKeywordStart(
        in characters: [Character],
        from start: Int,
        keywords: [[Character]]
    ) -> Int? {
        var result: Int? = nil
        for keyword in keywords {
            guard let found = index(of: keyword, from: start, in: characters) else {
                continue
            }
            if let currentResult = result {
                if found < currentResult {
                    result = found
                }
            } else {
                result = found
            }
        }
        return result
    }

    private func keywordLength(
        at start: Int,
        in characters: [Character],
        keywords: [[Character]]
    ) -> Int? {
        for keyword in keywords where starts(with: keyword, at: start, in: characters) {
            return keyword.count
        }
        return nil
    }

    private func stripComments(_ source: String) -> String {
        var output: String = source
        while let startRange = output.range(of: "/*") {
            guard let endRange = output[startRange.upperBound...].range(of: "*/") else {
                break
            }
            let removedRange = startRange.lowerBound..<endRange.upperBound
            output.replaceSubrange(removedRange, with: "")
        }
        return output
    }

    private func parseFrames(from bodyText: String) -> [SVGParsedKeyframe] {
        let characters: [Character] = Array(bodyText)
        var cursor: Int = 0
        var output: [SVGParsedKeyframe] = []

        while cursor < characters.count {
            cursor = skipWhitespace(characters, from: cursor)
            if cursor >= characters.count {
                break
            }

            guard let openBrace = index(of: "{", from: cursor, in: characters) else {
                break
            }
            let selectorText: String = String(characters[cursor..<openBrace])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let selectors: [String] = selectorText
                .split(separator: ",")
                .map { token in
                    token
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                }
                .filter { !$0.isEmpty }

            guard let closeBrace = matchingBraceEnd(openBraceIndex: openBrace, characters: characters) else {
                break
            }

            let declarationText: String = String(characters[(openBrace + 1)..<closeBrace])
            let declarations: [String: String] = declarationParser.parse(declarationText)

            for selector in selectors {
                if let offset = parseOffset(from: selector) {
                    output.append(.init(offset: offset, declarations: declarations))
                }
            }

            cursor = closeBrace + 1
        }

        return output.sorted { $0.offset < $1.offset }
    }

    private func parseOffset(from selector: String) -> Double? {
        let normalized = selector.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        case "from":
            return 0
        case "to":
            return 1
        default:
            break
        }
        if !normalized.hasSuffix("%") {
            return nil
        }
        let rawNumber: String = String(normalized.dropLast())
        guard let parsed = Double(rawNumber) else {
            return nil
        }
        let normalizedOffset = parsed / 100
        if normalizedOffset < 0 || normalizedOffset > 1 {
            return nil
        }
        return normalizedOffset
    }

    private func skipWhitespace(_ characters: [Character], from start: Int) -> Int {
        var index: Int = start
        while index < characters.count {
            if characters[index].isWhitespace {
                index += 1
            } else {
                break
            }
        }
        return index
    }

    private func starts(with pattern: [Character], at index: Int, in characters: [Character]) -> Bool {
        guard index + pattern.count <= characters.count else {
            return false
        }
        let end = index + pattern.count
        return Array(characters[index..<end]) == pattern
    }

    private func index(of pattern: [Character], from start: Int, in characters: [Character]) -> Int? {
        guard !pattern.isEmpty else {
            return nil
        }
        guard start < characters.count else {
            return nil
        }
        var index: Int = start
        while index <= characters.count - pattern.count {
            if starts(with: pattern, at: index, in: characters) {
                return index
            }
            index += 1
        }
        return nil
    }

    private func index(of target: Character, from start: Int, in characters: [Character]) -> Int? {
        var index = start
        while index < characters.count {
            if characters[index] == target {
                return index
            }
            index += 1
        }
        return nil
    }

    private func matchingBraceEnd(openBraceIndex: Int, characters: [Character]) -> Int? {
        var depth = 0
        var index = openBraceIndex
        while index < characters.count {
            if characters[index] == "{" {
                depth += 1
            } else if characters[index] == "}" {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
            index += 1
        }
        return nil
    }
}
