struct SVGDocument: Sendable, Equatable {
    var size: SVGSize?
    var viewBox: SVGRect?
    var nodes: [SVGNode]
    var animations: [SVGSMILAnimation]
    var styleRules: [SVGStyleRule]
    var clipPaths: [String: [SVGNode]]
    var filterDefinitions: [String: SVGFilterDefinition]
    var unsupportedFeatures: [String: Int]
    var animationsByTargetID: [String: [SVGSMILAnimation]]

    var hasUnsupportedFeatures: Bool {
        !unsupportedFeatures.isEmpty
    }

    init(
        size: SVGSize? = nil,
        viewBox: SVGRect? = nil,
        nodes: [SVGNode] = [],
        animations: [SVGSMILAnimation] = [],
        styleRules: [SVGStyleRule] = [],
        clipPaths: [String: [SVGNode]] = [:],
        filterDefinitions: [String: SVGFilterDefinition] = [:],
        unsupportedFeatures: [String: Int] = [:],
        animationsByTargetID: [String: [SVGSMILAnimation]]? = nil
    ) {
        self.size = size
        self.viewBox = viewBox
        self.nodes = nodes
        self.animations = animations
        self.styleRules = styleRules
        self.clipPaths = clipPaths
        self.filterDefinitions = filterDefinitions
        self.unsupportedFeatures = unsupportedFeatures
        self.animationsByTargetID = animationsByTargetID ?? Self.groupAnimationsByTarget(animations)
    }

    func animationIDs(
        forTargetID targetID: String,
        includeSyntheticID: Bool = true
    ) -> [SVGSMILAnimation] {
        if includeSyntheticID {
            return animationsByTargetID[targetID] ?? []
        }
        return animations.filter { animation in
            animation.targetElementID == targetID
        }
    }

    private static func groupAnimationsByTarget(
        _ animations: [SVGSMILAnimation]
    ) -> [String: [SVGSMILAnimation]] {
        var output: [String: [SVGSMILAnimation]] = [:]
        output.reserveCapacity(max(0, animations.count))
        for animation in animations {
            output[animation.targetElementID, default: []].append(animation)
            if animation.targetSyntheticID != animation.targetElementID {
                output[animation.targetSyntheticID, default: []].append(animation)
            }
        }
        return output
    }
}
