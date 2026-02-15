import Foundation

enum SVGRenderConfigurationSignature {
    private static let emptyIdentifier: String = "empty"
    private static let separator: String = "|"
    private static let listSeparator: String = ";"

    static func fingerprint(for configuration: SVGRenderConfiguration) -> String {
        let resolverTag: String = if configuration.resolver == nil {
            "resolver:none"
        } else {
            "resolver:present"
        }

        if configuration.idOverrides.isEmpty {
            return "\(resolverTag)\(separator)\(emptyIdentifier)"
        }

        let sortedKeys: [String] = configuration.idOverrides
            .keys
            .sorted()

        var chunks: [String] = []
        chunks.reserveCapacity(sortedKeys.count + 2)

        for key in sortedKeys {
            if let override = configuration.idOverrides[key] {
                let line: String = "\(key)=\(overrideFingerprint(override))"
                chunks.append(line)
            }
        }

        return "\(resolverTag)\(separator)\(chunks.joined(separator: listSeparator))"
    }

    static func overrideFingerprint(_ override: NodeOverride) -> String {
        var chunks: [String] = []
        if let fill = override.fill {
            chunks.append("fill:\(paintFingerprint(fill))")
        }
        if let stroke = override.stroke {
            chunks.append("stroke:\(paintFingerprint(stroke))")
        }
        if let strokeWidth = override.strokeWidth {
            chunks.append("strokeWidth:\(strokeWidth)")
        }
        if let opacity = override.opacity {
            chunks.append("opacity:\(opacity)")
        }
        if let scale = override.scale {
            chunks.append("scale:\(scale.width)x\(scale.height)")
        }
        if let offset = override.offset {
            chunks.append("offset:\(offset.x),\(offset.y)")
        }
        if chunks.isEmpty {
            return "none"
        }

        return chunks.joined(separator: listSeparator)
    }

    static func paintFingerprint(_ paint: SVGPaint) -> String {
        switch paint {
        case .none:
            return "none"
        case .currentColor:
            return "currentColor"
        case .color(let color):
            return "color:\(color.red):\(color.green):\(color.alpha):\(color.blue)"
        }
    }
}
