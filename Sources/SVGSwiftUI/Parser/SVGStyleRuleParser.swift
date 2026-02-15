import Foundation

struct SVGStyleRuleParser {
    private let declarationParser = SVGStyleDeclarationParser()

    func parse(_ styleText: String) -> [SVGStyleRule] {
        let noComments = stripComments(styleText)
        let text = noComments
        var rules: [SVGStyleRule] = []

        var cursorIndex: String.Index = text.startIndex
        while cursorIndex < text.endIndex {
            guard let openBraceIndex = text[cursorIndex...].firstIndex(of: "{") else {
                break
            }

            guard let closeBraceIndex = text[openBraceIndex...].dropFirst().firstIndex(of: "}") else {
                break
            }

            let selectorText = String(text[cursorIndex..<openBraceIndex])
            let declarationText = String(text[text.index(after: openBraceIndex)..<closeBraceIndex])
            let selectors = parseSelectors(selectorText)
            let declarations = declarationParser.parse(declarationText)

            if !declarations.isEmpty {
                for selector in selectors {
                    rules.append(
                        SVGStyleRule(selector: selector, declarations: declarations)
                    )
                }
            }

            cursorIndex = text.index(after: closeBraceIndex)
        }

        return rules
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

