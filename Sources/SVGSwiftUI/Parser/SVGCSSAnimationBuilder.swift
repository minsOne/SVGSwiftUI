import Foundation

extension SVGParser {
    private struct ParsedCSSAnimation {
        var name: String?
        var duration: Double?
        var delay: Double?
        var interpolation: SVGSMILAnimationValueInterpolation
        var keySplines: String?
        var repeatCount: SVGSMILAnimationRepeatCount?
        var fill: SVGSMILAnimationFill
        var direction: String?
    }

    private static let supportedCSSAnimationProperties: Set<String> = [
        "opacity",
        "fill",
        "fill-opacity",
        "stroke",
        "stroke-opacity",
        "stroke-width",
        "font-size",
        "transform",
        "stroke-dasharray",
        "stroke-dashoffset"
    ]

    private static let defaultAnimationFill: SVGSMILAnimationFill = .remove

    func buildCSSAnimations(
        for nodes: [SVGNode],
        styleRules: [SVGStyleRule],
        keyframeDefinitions: [String: SVGParsedKeyframeDefinition],
        unsupportedFeatures: inout [String: Int]
    ) -> [SVGSMILAnimation] {
        var output: [SVGSMILAnimation] = []
        let styleParser = SVGStyleDeclarationParser()

        for node in flatten(nodes: nodes) {
            let declarations = matchingDeclarations(for: node, styleRules: styleRules, styleDeclarationParser: styleParser)
            let descriptors = parseAnimationDescriptors(
                from: declarations,
                unsupportedFeatures: &unsupportedFeatures
            )

            guard !descriptors.isEmpty else {
                continue
            }

            for descriptor in descriptors {
                guard let animationName = descriptor.name else {
                    continue
                }
                guard let duration = descriptor.duration, duration > 0 else {
                    continue
                }
                let keyframeName = animationName.lowercased()
                guard let keyframeDefinition = keyframeDefinitions[keyframeName] else {
                    unsupportedFeatures["css:keyframes:\(keyframeName)", default: 0] += 1
                    continue
                }
                let normalizedDirection: String = (descriptor.direction ?? "normal").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !normalizedDirection.isEmpty && normalizedDirection != "normal" && normalizedDirection != "reverse" {
                    unsupportedFeatures["css:direction:\(normalizedDirection)", default: 0] += 1
                }
                let reversedFrames: Bool = normalizedDirection == "reverse"

                for property in SVGParser.supportedCSSAnimationProperties {
                    if let animation = animationFor(
                        node: node,
                        property: property,
                        keyframes: keyframeDefinition,
                        duration: duration,
                        delay: descriptor.delay,
                        interpolation: descriptor.interpolation,
                        keySplines: descriptor.keySplines,
                        repeatCount: descriptor.repeatCount,
                        fillMode: descriptor.fill,
                        reversedFrames: reversedFrames
                    ) {
                        output.append(animation)
                    }
                }
            }
        }

        return output
    }

    private func animationFor(
        node: SVGNode,
        property: String,
        keyframes: SVGParsedKeyframeDefinition,
        duration: Double,
        delay: Double?,
        interpolation: SVGSMILAnimationValueInterpolation,
        keySplines: String?,
        repeatCount: SVGSMILAnimationRepeatCount?,
        fillMode: SVGSMILAnimationFill,
        reversedFrames: Bool
    ) -> SVGSMILAnimation? {
        var candidateFrames: [SVGParsedKeyframe] = []
        for frame in keyframes.frames {
            if let raw = frame.declarations[property], !raw.isEmpty {
                candidateFrames.append(frame)
            }
        }
        if candidateFrames.count < 2 {
            return nil
        }

        if reversedFrames {
            candidateFrames.reverse()
        }

        var offsets: [String] = []
        var values: [String] = []
        for frame in candidateFrames {
            if let value = frame.declarations[property] {
                let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if sanitized.isEmpty {
                    continue
                }
                let offsetText: String = String(frame.offset)
                offsets.append(offsetText)
                values.append(sanitized)
            }
        }
        if values.count < 2 {
            return nil
        }

        let valueText = values.joined(separator: ";")
        let keyTimesText = offsets.joined(separator: ";")

        let timing = SVGSMILAnimationTiming(
            begin: delay == nil ? [] : [delay!],
            dur: duration,
            end: [],
            repeatCount: repeatCount,
            repeatDur: nil,
            fill: fillMode
        )

        return SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: node.base.id ?? node.base.syntheticID,
            targetSyntheticID: node.base.syntheticID,
            attributes: [:],
            timing: timing,
            attributeName: property,
            values: SVGSMILAnimationValue(kind: "values", raw: valueText),
            type: property == "transform" ? "transform" : nil,
            keyTimes: keyTimesText,
            keySplines: interpolation == .spline ? keySplines : nil,
            interpolation: interpolation,
            fromValue: nil,
            toValue: nil,
            byValue: nil
        )
    }

    private func flatten(nodes: [SVGNode]) -> [SVGNode] {
        var output: [SVGNode] = []
        for node in nodes {
            output.append(node)
            for child in node.children {
                output.append(contentsOf: flatten(nodes: [child]))
            }
        }
        return output
    }

    private func matchingDeclarations(
        for node: SVGNode,
        styleRules: [SVGStyleRule],
        styleDeclarationParser: SVGStyleDeclarationParser
    ) -> [String: String] {
        let matchingRules: [SVGStyleRule] = sortedMatchingRules(for: node, in: styleRules)
        var merged: [String: String] = [:]
        for rule in matchingRules {
            for item in rule.declarations {
                let key = item.key
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                merged[key] = item.value
            }
        }
        if let rawStyle = node.base.attributes["style"] {
            let inlineDeclarations = styleDeclarationParser.parse(rawStyle)
            for item in inlineDeclarations {
                merged[item.key] = item.value
            }
        }
        return merged
    }

    private func sortedMatchingRules(for node: SVGNode, in styleRules: [SVGStyleRule]) -> [SVGStyleRule] {
        var candidates: [(specificity: Int, order: Int, rule: SVGStyleRule)] = []
        for (index, rule) in styleRules.enumerated() {
            if matches(node: node, selector: rule.selector) {
                let selectorSpecificity = specificity(for: rule.selector)
                candidates.append((selectorSpecificity, index, rule))
            }
        }

        let sortedCandidates: [(specificity: Int, order: Int, rule: SVGStyleRule)] = candidates.sorted {
            if $0.specificity == $1.specificity {
                return $0.order < $1.order
            }
            return $0.specificity < $1.specificity
        }

        return sortedCandidates.map(\.rule)
    }

    private func matches(node: SVGNode, selector: SVGStyleSelector) -> Bool {
        switch selector {
        case .any:
            return true
        case .id(let selectorID):
            return node.base.id == selectorID
        case .class(let selectorClass):
            let classNames = parseClassNames(from: node.base.attributes["class"])
            return classNames.contains(selectorClass)
        case .element(let selectorElement):
            return selectorElement == node.elementKind.rawValue
        }
    }

    private func parseClassNames(from value: String?) -> Set<String> {
        guard let rawClass = value else {
            return []
        }
        let parsedParts = rawClass.split(whereSeparator: \.isWhitespace)
        var classNames: Set<String> = []
        classNames.reserveCapacity(parsedParts.count)
        for part in parsedParts {
            let className = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if !className.isEmpty {
                classNames.insert(className)
            }
        }
        return classNames
    }

    private func specificity(for selector: SVGStyleSelector) -> Int {
        switch selector {
        case .id:
            return 100
        case .class:
            return 10
        case .element:
            return 1
        case .any:
            return 0
        }
    }

    private func parseAnimationDescriptors(
        from declarations: [String: String],
        unsupportedFeatures: inout [String: Int]
    ) -> [ParsedCSSAnimation] {
        var descriptors: [ParsedCSSAnimation] = []
        if let rawAnimation = declarations["animation"] {
            descriptors = parseAnimationShorthand(rawAnimation)
        }

        var propertyDescriptors: [String: [String]] = [:]
        propertyDescriptors["name"] = parseLonghandList(from: declarations["animation-name"])
        propertyDescriptors["duration"] = parseLonghandList(from: declarations["animation-duration"])
        propertyDescriptors["delay"] = parseLonghandList(from: declarations["animation-delay"])
        propertyDescriptors["timing-function"] = parseLonghandList(from: declarations["animation-timing-function"])
        propertyDescriptors["iteration-count"] = parseLonghandList(from: declarations["animation-iteration-count"])
        propertyDescriptors["fill-mode"] = parseLonghandList(from: declarations["animation-fill-mode"])
        propertyDescriptors["direction"] = parseLonghandList(from: declarations["animation-direction"])

        let hasLonghand: Bool = propertyDescriptors.values.contains(where: { !$0.isEmpty })
        if descriptors.isEmpty && hasLonghand {
            descriptors = parseLonghandDescriptors(from: propertyDescriptors)
        }

        for (index, rawValues) in propertyDescriptors {
            switch index {
            case "name":
                applyNameValues(rawValues, to: &descriptors)
            case "duration":
                applyDurationValues(rawValues, to: &descriptors)
            case "delay":
                applyDelayValues(rawValues, to: &descriptors)
            case "timing-function":
                applyTimingFunctionValues(
                    rawValues,
                    to: &descriptors,
                    unsupportedFeatures: &unsupportedFeatures
                )
            case "iteration-count":
                applyIterationValues(rawValues, to: &descriptors, unsupportedFeatures: &unsupportedFeatures)
            case "fill-mode":
                applyFillModeValues(rawValues, to: &descriptors)
            case "direction":
                applyDirectionValues(rawValues, to: &descriptors)
            default:
                break
            }
        }

        var output: [ParsedCSSAnimation] = []
        output.reserveCapacity(descriptors.count)
        for descriptor in descriptors {
            let hasName: Bool = {
                if let rawName = descriptor.name {
                    if rawName == "none" {
                        return false
                    }
                    let normalizedName = rawName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return !normalizedName.isEmpty
                }
                return false
            }()
            if hasName {
                output.append(descriptor)
            }
        }
        return output
    }

    private func parseAnimationShorthand(_ raw: String) -> [ParsedCSSAnimation] {
        let groups = splitTopLevel(raw, separator: ",")
        if groups.isEmpty {
            return []
        }

        var output: [ParsedCSSAnimation] = []
        output.reserveCapacity(groups.count)

        for item in groups {
            let normalizedGroup = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedGroup.isEmpty {
                continue
            }

            var descriptor = ParsedCSSAnimation(
                name: nil,
                duration: nil,
                delay: nil,
                interpolation: .linear,
                keySplines: nil,
                repeatCount: nil,
                fill: SVGParser.defaultAnimationFill,
                direction: nil
            )
            var parsedTimes: [Double] = []

            let tokens = splitWhitespaceOutsideParentheses(normalizedGroup)
            for token in tokens {
                let lowerToken = token.lowercased()
                if lowerToken == "normal" {
                    continue
                }
                if let duration = parseAnimationDuration(lowerToken), parsedTimes.count == 0 {
                    parsedTimes.append(duration)
                    descriptor.duration = duration
                    continue
                }
                if let delay = parseAnimationDuration(lowerToken), parsedTimes.count >= 1 {
                    descriptor.delay = delay
                    parsedTimes.append(delay)
                    continue
                }
                if lowerToken == "alternate" || lowerToken == "alternate-reverse" {
                    descriptor.direction = lowerToken
                    continue
                }
                if lowerToken == "reverse" {
                    descriptor.direction = "reverse"
                    continue
                }

                if let repeatCount = parseRepeatCount(lowerToken) {
                    descriptor.repeatCount = repeatCount
                    continue
                }

                if let fillMode = parseFillMode(lowerToken) {
                    descriptor.fill = fillMode
                    continue
                }

                if let timing = parseTimingToken(
                    lowerToken
                ) {
                    descriptor.interpolation = timing.interpolation
                    descriptor.keySplines = timing.keySplines
                    continue
                }

                if descriptor.name == nil && isAnimationNameCandidate(lowerToken) {
                    descriptor.name = lowerToken
                    continue
                }
            }

            output.append(descriptor)
        }

        return output
    }

    private func parseLonghandDescriptors(from lists: [String: [String]]) -> [ParsedCSSAnimation] {
        var longestCount: Int = 0
        for value in lists.values {
            let count: Int = value.count
            if count > longestCount {
                longestCount = count
            }
        }

        if longestCount == 0 {
            return []
        }

        let defaults: ParsedCSSAnimation = ParsedCSSAnimation(
            name: nil,
            duration: nil,
            delay: nil,
            interpolation: .linear,
            keySplines: nil,
            repeatCount: nil,
            fill: SVGParser.defaultAnimationFill,
            direction: nil
        )

        var output: [ParsedCSSAnimation] = []
        output.reserveCapacity(longestCount)
        for _ in 0..<longestCount {
            output.append(defaults)
        }
        return output
    }

    private func parseLonghandList(from value: String?) -> [String] {
        let raw: [String] = splitTopLevel(value ?? "", separator: ",")
        var output: [String] = []
        output.reserveCapacity(raw.count)
        for item in raw {
            let normalized = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalized.isEmpty {
                output.append(normalized)
            }
        }
        return output
    }

    private func ensureDescriptorCount(_ count: Int, in descriptors: inout [ParsedCSSAnimation]) {
        if descriptors.count >= count {
            return
        }
        let defaults = ParsedCSSAnimation(
            name: nil,
            duration: nil,
            delay: nil,
            interpolation: .linear,
            keySplines: nil,
            repeatCount: nil,
            fill: SVGParser.defaultAnimationFill,
            direction: nil
        )
        while descriptors.count < count {
            descriptors.append(defaults)
        }
    }

    private func applyNameValues(
        _ values: [String]?,
        to descriptors: inout [ParsedCSSAnimation]
    ) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            descriptors[index].name = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    private func applyDurationValues(
        _ values: [String]?,
        to descriptors: inout [ParsedCSSAnimation]
    ) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let duration = parseAnimationDuration(normalized) else {
                continue
            }
            descriptors[index].duration = duration
        }
    }

    private func applyDelayValues(
        _ values: [String]?,
        to descriptors: inout [ParsedCSSAnimation]
    ) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let delay = parseAnimationDuration(normalized) else {
                continue
            }
            descriptors[index].delay = delay
        }
    }

    private func applyTimingFunctionValues(
        _ values: [String]?,
        to descriptors: inout [ParsedCSSAnimation],
        unsupportedFeatures: inout [String: Int]
    ) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if let timing = parseTimingToken(normalized) {
                descriptors[index].interpolation = timing.interpolation
                descriptors[index].keySplines = timing.keySplines
                continue
            }
            unsupportedFeatures["css:timing-function:\(normalized)", default: 0] += 1
        }
    }

    private func applyIterationValues(
        _ values: [String]?,
        to descriptors: inout [ParsedCSSAnimation],
        unsupportedFeatures: inout [String: Int]
    ) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            if let parsed = parseRepeatCount(value) {
                descriptors[index].repeatCount = parsed
                continue
            }
            unsupportedFeatures["css:iteration-count:\(value)", default: 0] += 1
        }
    }

    private func applyFillModeValues(_ values: [String]?, to descriptors: inout [ParsedCSSAnimation]) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            let value = values[index]
            if let fill = parseFillMode(value) {
                descriptors[index].fill = fill
            }
        }
    }

    private func applyDirectionValues(_ values: [String]?, to descriptors: inout [ParsedCSSAnimation]) {
        guard let values else {
            return
        }
        ensureDescriptorCount(values.count, in: &descriptors)
        for index in 0..<values.count {
            descriptors[index].direction = values[index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    private func parseAnimationDuration(_ value: String) -> Double? {
        return parseTime(value)
    }

    private func parseRepeatCount(_ value: String) -> SVGSMILAnimationRepeatCount? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return nil
        }
        if normalized == "infinite" {
            return .indefinite
        }
        guard let number = Double(normalized) else {
            return nil
        }
        if number < 0 {
            return nil
        }
        return .finite(number)
    }

    private func parseFillMode(_ value: String) -> SVGSMILAnimationFill? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return nil
        }
        if normalized == "forwards" || normalized == "both" {
            return .freeze
        }
        if normalized == "none" || normalized == "backwards" {
            return .remove
        }
        if normalized == "auto" || normalized == "normal" {
            return .remove
        }
        return nil
    }

    private func parseTimingToken(_ value: String) -> (interpolation: SVGSMILAnimationValueInterpolation, keySplines: String?)? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return nil
        }
        if normalized == "linear" {
            return (interpolation: .linear, keySplines: nil)
        }
        if normalized == "ease" {
            return (interpolation: .spline, keySplines: "0.25 0.1 0.25 1")
        }
        if normalized == "ease-in" {
            return (interpolation: .spline, keySplines: "0.42 0 1 1")
        }
        if normalized == "ease-out" {
            return (interpolation: .spline, keySplines: "0 0 0.58 1")
        }
        if normalized == "ease-in-out" {
            return (interpolation: .spline, keySplines: "0.42 0 0.58 1")
        }
        guard normalized.hasPrefix("cubic-bezier("), normalized.hasSuffix(")") else {
            return nil
        }
        let insideStartIndex: Int = "cubic-bezier(".count
        let insideEndIndex: Int = normalized.count - 1
        if insideEndIndex <= insideStartIndex {
            return nil
        }
        let start = normalized.index(normalized.startIndex, offsetBy: insideStartIndex)
        let end = normalized.index(normalized.endIndex, offsetBy: -1)
        let inside = String(normalized[start..<end])
        let rawValues = splitTopLevel(inside, separator: ",")
        if rawValues.count != 4 {
            return nil
        }
        var parsed: [String] = []
        for raw in rawValues {
            let normalizedValue = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if let parsedValue = Double(normalizedValue) {
                parsed.append(String(parsedValue))
            }
        }
        if parsed.count == 4 {
            return (interpolation: .spline, keySplines: parsed.joined(separator: " "))
        }
        return nil
    }

    private func isAnimationNameCandidate(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return false
        }
        if parseTime(normalized) != nil {
            return false
        }
        if parseRepeatCount(normalized) != nil {
            return false
        }
        if parseFillMode(normalized) != nil {
            return false
        }
        if parseTimingToken(normalized) != nil {
            return false
        }
        if normalized == "alternate" || normalized == "alternate-reverse" || normalized == "reverse" {
            return false
        }
        return true
    }

    private func splitTopLevel(_ value: String, separator: Character) -> [String] {
        let characters: [Character] = Array(value)
        var output: [String] = []
        var nesting: Int = 0
        var quote: Character?
        var current: String = ""

        for character in characters {
            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                }
                current.append(character)
                continue
            }

            if character == "'" || character == "\"" {
                quote = character
                current.append(character)
                continue
            }

            if character == "(" {
                nesting += 1
                current.append(character)
                continue
            }
            if character == ")" && nesting > 0 {
                nesting -= 1
                current.append(character)
                continue
            }

            if character == separator && nesting == 0 {
                let normalizedCurrent = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalizedCurrent.isEmpty {
                    output.append(normalizedCurrent)
                }
                current.removeAll(keepingCapacity: false)
                continue
            }

            current.append(character)
        }

        let normalizedTail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedTail.isEmpty {
            output.append(normalizedTail)
        }

        return output
    }

    private func splitWhitespaceOutsideParentheses(_ value: String) -> [String] {
        var output: [String] = []
        var current: String = ""
        var depth: Int = 0

        for character in value {
            if character == "(" {
                depth += 1
                current.append(character)
                continue
            }
            if character == ")" && depth > 0 {
                depth -= 1
                current.append(character)
                continue
            }

            if character.isWhitespace && depth == 0 {
                let normalized = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty {
                    output.append(normalized)
                }
                current.removeAll(keepingCapacity: false)
                continue
            }

            current.append(character)
        }
        let normalized = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty {
            output.append(normalized)
        }
        return output
    }

    private func parseTime(_ value: String) -> Double? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return nil
        }
        if normalized.hasSuffix("ms") {
            let raw: String = String(normalized.dropLast(2))
            guard let number = Double(raw) else {
                return nil
            }
            return number / 1000.0
        }
        if normalized.hasSuffix("s") {
            let raw: String = String(normalized.dropLast(1))
            return Double(raw)
        }
        if normalized == "0" || normalized == "0.0" {
            return 0.0
        }
        return Double(normalized)
    }
}
