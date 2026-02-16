import Foundation

struct SVGStyleRuleParser {
    private let declarationParser = SVGStyleDeclarationParser()

    func parse(_ styleText: String) -> [SVGStyleRule] {
        let noComments = stripComments(styleText)
        let text = noComments
        var rules: [SVGStyleRule] = []

        let chars: [Character] = Array(text)
        var cursor = 0

        while cursor < chars.count {
            cursor = skipWhitespace(chars: chars, from: cursor)
            if cursor >= chars.count {
                break
            }

            guard let openBraceIndex = index(of: "{", chars: chars, from: cursor) else {
                break
            }

            let selectorText = String(
                chars[cursor..<openBraceIndex]
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let closeBraceIndex = matchingBraceEnd(
                from: openBraceIndex,
                chars: chars
            ) else {
                break
            }

            if selectorText.hasPrefix("@") {
                cursor = closeBraceIndex + 1
                continue
            }

            let declarationText = String(
                chars[(openBraceIndex + 1)..<closeBraceIndex]
            )
            let selectors = parseSelectors(selectorText)
            let declarations = declarationParser.parse(declarationText)

            if !declarations.isEmpty {
                for selector in selectors {
                    rules.append(
                        SVGStyleRule(selector: selector, declarations: declarations)
                    )
                }
            }

            cursor = closeBraceIndex + 1
        }

        return rules
    }

    private func skipWhitespace(chars: [Character], from start: Int) -> Int {
        var index: Int = start
        while index < chars.count {
            if chars[index].isWhitespace {
                index += 1
                continue
            }
            break
        }
        return index
    }

    private func index(of target: Character, chars: [Character], from start: Int) -> Int? {
        guard start < chars.count else {
            return nil
        }

        var index = start
        while index < chars.count {
            if chars[index] == target {
                return index
            }
            index += 1
        }
        return nil
    }

    private func matchingBraceEnd(from openBraceIndex: Int, chars: [Character]) -> Int? {
        var depth = 0
        var index = openBraceIndex

        while index < chars.count {
            let item = chars[index]
            if item == "{" {
                depth += 1
            } else if item == "}" {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
            index += 1
        }

        return nil
    }

    private func parseSelectors(_ text: String) -> [SVGStyleSelector] {
        let parts = text.split(separator: ",")
        var selectors: [SVGStyleSelector] = []

        for rawSelector in parts {
            if let selector = parseSelector(String(rawSelector)) {
                selectors.append(selector)
            }
        }

        return selectors
    }

    private func parseSelector(_ raw: String) -> SVGStyleSelector? {
        let selector = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selector.isEmpty else {
            return nil
        }

        if selector.hasPrefix("@") {
            return nil
        }

        if selector.contains(" ") {
            return nil
        }

        if selector == "*" {
            return .any
        }

        if selector.hasPrefix("#") {
            let idValue = selector.dropFirst()
            guard !idValue.isEmpty else {
                return nil
            }
            return .id(String(idValue))
        }

        if selector.hasPrefix(".") {
            let classValue = selector.dropFirst()
            guard !classValue.isEmpty else {
                return nil
            }
            return .class(String(classValue))
        }

        return .element(selector.lowercased())
    }

    private func stripComments(_ value: String) -> String {
        var output = value
        while let startRange = output.range(of: "/*") {
            guard let endRange = output[startRange.upperBound...].range(of: "*/") else {
                break
            }
            let closedRange = startRange.lowerBound..<endRange.upperBound
            output.replaceSubrange(closedRange, with: "")
        }
        return output
    }
}
