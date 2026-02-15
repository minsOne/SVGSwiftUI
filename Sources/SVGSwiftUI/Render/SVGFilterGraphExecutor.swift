internal enum SVGFilterGraphExecutor {
    private static let sourceGraphicName: String = "SourceGraphic"
    private static let sourceAlphaName: String = "SourceAlpha"

    static func defaultAvailableSources() -> Set<String> {
        Set<String>(minimumSourceSet())
    }

    static func minimumSourceSet() -> [String] {
        [sourceGraphicName, sourceAlphaName]
    }

    static func canExecute(_ primitive: SVGFilterPrimitive, availableSources: Set<String>) -> Bool {
        switch primitive {
        case .unsupported:
            return false
        default:
            break
        }

        let requiredSourceNames: Set<String> = requiredSourceNames(for: primitive)
        for sourceName in requiredSourceNames {
            if !isSourceAvailable(sourceName, availableSources: availableSources) {
                return false
            }
        }

        return true
    }

    static func requiredSourceNames(for primitive: SVGFilterPrimitive) -> Set<String> {
        switch primitive {
        case .gaussianBlur(_, _, let inSource, _):
            let resolvedSource: String = inSource ?? sourceGraphicName
            return [resolvedSource]
        case .offset(_, _, let inSource, _):
            let resolvedSource: String = inSource ?? sourceGraphicName
            return [resolvedSource]
        case .blend(_, let inSource, let inSourceTwo, _):
            let resolvedSourceOne: String = inSource ?? sourceGraphicName
            let resolvedSourceTwo: String = inSourceTwo ?? sourceGraphicName
            return [resolvedSourceOne, resolvedSourceTwo]
        case .composite(_, let inSource, let inSourceTwo, _, _, _, _, _):
            let resolvedSourceOne: String = inSource ?? sourceGraphicName
            let resolvedSourceTwo: String = inSourceTwo ?? sourceGraphicName
            return [resolvedSourceOne, resolvedSourceTwo]
        case .colorMatrix(_, let inSource, _):
            let resolvedSource: String = inSource ?? sourceGraphicName
            return [resolvedSource]
        case .unsupported:
            return []
        }
    }

    static func resolvedResultName(for primitive: SVGFilterPrimitive) -> String? {
        switch primitive {
        case .gaussianBlur(_, _, _, let result):
            return normalizedSourceName(from: result)
        case .offset(_, _, _, let result):
            return normalizedSourceName(from: result)
        case .blend(_, _, _, let result):
            return normalizedSourceName(from: result)
        case .composite(_, _, _, _, _, _, _, let result):
            return normalizedSourceName(from: result)
        case .colorMatrix(_, _, let result):
            return normalizedSourceName(from: result)
        case .unsupported:
            return nil
        }
    }

    static func isSourceAvailable(_ source: String, availableSources: Set<String>) -> Bool {
        let normalizedSource: String = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedSource.isEmpty {
            return false
        }
        return availableSources.contains(normalizedSource)
    }

    private static func normalizedSourceName(from value: String?) -> String? {
        let trimmedName: String = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedName.isEmpty {
            return nil
        }
        return trimmedName
    }
}
