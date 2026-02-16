import CoreGraphics
import Foundation

private enum SVGSMILStyleAttribute: String {
    case opacity
    case fillOpacity = "fill-opacity"
    case strokeOpacity = "stroke-opacity"
    case strokeWidth = "stroke-width"
    case fontSize = "font-size"
    case fill
    case stroke
    case transform
}

private enum SVGAnimateMotionRotateMode: Equatable {
    case none
    case auto
    case autoReverse
    case fixed(Double)

    init(rawValue: String) {
        let normalized: String = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.isEmpty || normalized == "auto" {
            self = .auto
            return
        }
        if normalized == "auto-reverse" {
            self = .autoReverse
            return
        }
        if let angle = parseStaticSMILDouble(normalized) {
            self = .fixed(angle)
            return
        }
        self = .auto
    }

    var shouldRotate: Bool {
        switch self {
        case .none:
            return false
        case .auto, .autoReverse, .fixed:
            return true
        }
    }
}

private enum SVGAnimateMotionSample {
    case none
    case positionOnly(point: CGPoint)
    case positionAndRotation(point: CGPoint, rotationDegrees: Double?)
}

private let defaultMotionPathSegmentCount: Int = 18

private func parseStaticSMILDouble(_ rawValue: String) -> Double? {
    let normalized: String = rawValue
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(normalized)
}

private struct SVGSMILEngineTimelineSample {
    let timelineProgress: Double
    let segmentProgress: Double
    let segmentIndex: Int
    let usesKeyTimes: Bool
}

private struct SVGSMILEngineAnimationSample {
    let animation: SVGSMILAnimation
    let sample: SVGSMILEngineTimelineSample
}

struct SVGSMILEngine {
    private static let millisecondsPerSecond: Double = 1000
    private static let motionPathParser: SVGPathDataParser = SVGPathDataParser()
    private static let motionPathCurveSegmentCount: Int = defaultMotionPathSegmentCount

    static func applyAnimations(
        to resolvedStyles: [String: SVGResolvedNodeStyle],
        animationsByTargetID: [String: [SVGSMILAnimation]],
        at elapsed: TimeInterval
    ) -> [String: SVGResolvedNodeStyle] {
        guard !animationsByTargetID.isEmpty else {
            return resolvedStyles
        }

        var updatedStyles: [String: SVGResolvedNodeStyle] = resolvedStyles

        for (targetID, animations) in animationsByTargetID {
            guard var resolvedNodeStyle = resolvedStyles[targetID] else {
                continue
            }
            var style = resolvedNodeStyle.style
            var transformOverride = resolvedNodeStyle.transformOverride
            var changed = false
            var transformAnimation: SVGSMILEngineAnimationSample?
            var animationByAttribute: [SVGSMILStyleAttribute: SVGSMILEngineAnimationSample] = [:]

            for animation in animations {
                guard let animationSample = animationSample(
                    for: animation,
                    elapsed: elapsed
                ) else {
                    continue
                }

                if animation.kind == .animateMotion {
                    transformAnimation = SVGSMILEngineAnimationSample(
                        animation: animation,
                        sample: animationSample
                    )
                    continue
                }

                guard let rawAttributeName = animation.attributeName else {
                    continue
                }
                let normalizedName = rawAttributeName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                guard let attribute = SVGSMILStyleAttribute(rawValue: normalizedName) else {
                    continue
                }

                let candidate = SVGSMILEngineAnimationSample(
                    animation: animation,
                    sample: animationSample
                )
                if attribute == .transform {
                    transformAnimation = candidate
                } else {
                    animationByAttribute[attribute] = candidate
                }
            }

                if let transformCandidate = transformAnimation {
                    if transformCandidate.animation.kind == .animateMotion {
                        if applyAnimateMotionAnimation(
                            animation: transformCandidate.animation,
                            transformOverride: &transformOverride,
                            sample: transformCandidate.sample
                        ) {
                            changed = true
                        }
                    } else {
                        if apply(
                            animation: transformCandidate.animation,
                            attribute: .transform,
                            to: &style,
                            transformOverride: &transformOverride,
                            elapsed: elapsed,
                            sample: transformCandidate.sample
                        ) {
                            changed = true
                        }
                    }
                }

                for (attribute, candidate) in animationByAttribute {
                    if apply(
                        animation: candidate.animation,
                        attribute: attribute,
                        to: &style,
                        transformOverride: &transformOverride,
                        elapsed: elapsed,
                        sample: candidate.sample
                    ) {
                        changed = true
                    }
                }
            if changed {
                resolvedNodeStyle.style = style
                resolvedNodeStyle.transformOverride = transformOverride
                updatedStyles[targetID] = resolvedNodeStyle
            }
        }

        return updatedStyles
    }

    static func groupAnimationsByTarget(_ animations: [SVGSMILAnimation]) -> [String: [SVGSMILAnimation]] {
        var output: [String: [SVGSMILAnimation]] = [:]
        for animation in animations {
            output[animation.targetElementID, default: []].append(animation)
        }
        return output
    }

    private static func apply(
        animation: SVGSMILAnimation,
        attribute: SVGSMILStyleAttribute,
        to style: inout SVGResolvedStyle,
        transformOverride: inout CGAffineTransform?,
        elapsed: TimeInterval,
        sample: SVGSMILEngineTimelineSample
    ) -> Bool {
        switch attribute {
        case .opacity:
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.opacity
                )
            }
            let currentOpacity = style.opacity
            if let animatedOpacity = sampleNumericValue(
                from: currentOpacity,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.opacity = animatedOpacity
                return true
            }
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.opacity
                )
            }
            return false
        case .fillOpacity:
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.fillOpacity
                )
            }
            let currentValue = style.fillOpacity
            if let animatedValue = sampleNumericValue(
                from: currentValue,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.fillOpacity = animatedValue
                return true
            }
            if animation.kind == .set {
                return applySetValue(value: animation.toValue, into: &style.fillOpacity)
            }
            return false
        case .strokeOpacity:
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.strokeOpacity
                )
            }
            let currentValue = style.strokeOpacity
            if let animatedValue = sampleNumericValue(
                from: currentValue,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.strokeOpacity = animatedValue
                return true
            }
            if animation.kind == .set {
                return applySetValue(value: animation.toValue, into: &style.strokeOpacity)
            }
            return false
        case .strokeWidth:
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.strokeWidth
                )
            }
            let currentValue = style.strokeWidth
            if let animatedValue = sampleNumericValue(
                from: currentValue,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.strokeWidth = max(animatedValue, 0)
                return true
            }
            return false
        case .fontSize:
            if animation.kind == .set {
                return applySetValue(
                    value: animation.toValue,
                    into: &style.fontSize
                )
            }
            let currentValue = style.fontSize
            if let animatedValue = sampleNumericValue(
                from: currentValue,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.fontSize = animatedValue
                return true
            }
            return false
        case .fill:
            if animation.kind == .set, let nextPaint = parsePaint(animation.toValue) {
                style.fill = nextPaint
                return true
            }
            if let animatedFill = samplePaintValue(
                baseValue: style.fill,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.fill = animatedFill
                return true
            }
            return false
        case .stroke:
            if animation.kind == .set, let nextPaint = parsePaint(animation.toValue) {
                style.stroke = nextPaint
                return true
            }
            if let animatedStroke = samplePaintValue(
                baseValue: style.stroke,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                style.stroke = animatedStroke
                return true
            }
            return false
        case .transform:
            if animation.kind == .set {
                if let nextTransform = parseTransformValue(
                    animation.toValue,
                    type: animation.type
                ) {
                    transformOverride = nextTransform
                    return true
                }
                return false
            }

            if let animatedTransform = sampleTransformValue(
                baseValue: transformOverride ?? .identity,
                animation: animation,
                elapsed: elapsed,
                sample: sample
            ) {
                transformOverride = animatedTransform
                return true
            }
            return false
        }
    }

    private static func applyAnimateMotionAnimation(
        animation: SVGSMILAnimation,
        transformOverride: inout CGAffineTransform?,
        sample: SVGSMILEngineTimelineSample
    ) -> Bool {
        let rotateValue: String = animation.attributes["rotate"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        let rotateMode: SVGAnimateMotionRotateMode = SVGAnimateMotionRotateMode(rawValue: rotateValue)

        if let nextTransform: CGAffineTransform = motionTransform(
            for: animation,
            progress: sample.timelineProgress,
            rotateMode: rotateMode
        ) {
            transformOverride = nextTransform
            return true
        }
        return false
    }

    private static func animationSample(
        for animation: SVGSMILAnimation,
        elapsed: TimeInterval
    ) -> SVGSMILEngineTimelineSample? {
        timelineSample(
            for: animation.timing,
            elapsed: elapsed,
            valueCount: nil,
            interpolation: animation.interpolation,
            keyTimes: animation.keyTimes,
            keySplines: animation.keySplines,
            fillMode: animation.timing.fill
        )
    }

    private static func motionTransform(
        for animation: SVGSMILAnimation,
        progress: Double,
        rotateMode: SVGAnimateMotionRotateMode
    ) -> CGAffineTransform? {
        guard progress >= 0 && progress <= 1 else {
            return nil
        }

        let pointsResult = sampleMotionPoint(
            for: animation,
            progress: progress,
            rotateMode: rotateMode
        )
        switch pointsResult {
        case .positionAndRotation(let point, let rotationDegrees):
            let translate: CGAffineTransform = .init(
                translationX: point.x,
                y: point.y
            )
            guard let rotationDegrees else {
                return translate
            }
            let rotate: CGAffineTransform = .init(
                rotationAngle: CGFloat(rotationDegrees * Double.pi / 180)
            )
            return rotate.concatenating(translate)
        case .positionOnly(let point):
            return .init(translationX: point.x, y: point.y)
        case .none:
            return nil
        }
    }

    private static func sampleMotionPoint(
        for animation: SVGSMILAnimation,
        progress: Double,
        rotateMode: SVGAnimateMotionRotateMode
    ) -> SVGAnimateMotionSample {
        if let pathData: String = animation.attributes["path"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pathData.isEmpty {
            return sampleMotionPointFromPath(
                pathData: pathData,
                progress: progress,
                rotateMode: rotateMode
            )
        }

        return sampleMotionPointFromCoordinates(
            fromValue: animation.fromValue,
            toValue: animation.toValue,
            progress: progress,
            rotateMode: rotateMode
        )
    }

    private static func sampleMotionPointFromCoordinates(
        fromValue: String?,
        toValue: String?,
        progress: Double,
        rotateMode: SVGAnimateMotionRotateMode
    ) -> SVGAnimateMotionSample {
        guard
            let fromPoint: CGPoint = parseSMILPoint(fromValue),
            let toPoint: CGPoint = parseSMILPoint(toValue)
        else {
            return .none
        }

        let clamped: Double = clamp(progress, min: 0, max: 1)
        let x: Double = fromPoint.x + (toPoint.x - fromPoint.x) * clamped
        let y: Double = fromPoint.y + (toPoint.y - fromPoint.y) * clamped
        guard rotateMode.shouldRotate else {
            return .positionOnly(point: CGPoint(x: x, y: y))
        }

        let dx: Double = toPoint.x - fromPoint.x
        let dy: Double = toPoint.y - fromPoint.y
        switch rotateMode {
        case .fixed(let angleDegrees):
            return .positionAndRotation(
                point: CGPoint(x: x, y: y),
                rotationDegrees: angleDegrees
            )
        case .auto:
            let direction = CGPoint(x: dx, y: dy)
            if direction == .zero {
                return .positionOnly(point: CGPoint(x: x, y: y))
            }
            let radians: Double = atan2(Double(direction.y), Double(direction.x))
            let degrees: Double = radians * 180 / .pi
            return .positionAndRotation(point: CGPoint(x: x, y: y), rotationDegrees: degrees)
        case .autoReverse:
            let direction = CGPoint(x: dx, y: dy)
            if direction == .zero {
                return .positionOnly(point: CGPoint(x: x, y: y))
            }
            let radians: Double = atan2(Double(direction.y), Double(direction.x))
            let degrees: Double = (radians * 180 / .pi) + 180
            return .positionAndRotation(point: CGPoint(x: x, y: y), rotationDegrees: degrees)
        case .none:
            return .positionOnly(point: CGPoint(x: x, y: y))
        }
    }

    private static func sampleMotionPointFromPath(
        pathData: String,
        progress: Double,
        rotateMode: SVGAnimateMotionRotateMode
    ) -> SVGAnimateMotionSample {
        let commands: [SVGPathCommand]
        do {
            commands = try motionPathParser.parse(pathData)
        } catch {
            return .none
        }

        var points: [CGPoint] = []
        var directions: [CGPoint] = []
        points.reserveCapacity(commands.count * motionPathCurveSegmentCount)
        directions.reserveCapacity(commands.count * motionPathCurveSegmentCount)

        buildPathSamples(
            from: commands,
            intoPoints: &points,
            intoDirections: &directions
        )

        if points.isEmpty {
            return .none
        }

        let clamped: Double = clamp(progress, min: 0, max: 1)

        if points.count == 1 {
            return .positionOnly(point: points[0])
        }

        let targetLength: Double = clamped * motionPathLength(points: points)
        if targetLength <= 0 {
            return .positionOnly(point: points[0])
        }

        let sampleAndRotation: (point: CGPoint, direction: CGPoint)? = samplePoint(
            on: points,
            directions: directions,
            atLength: targetLength
        )
        guard let sampleAndRotation else {
            return .positionOnly(point: points[points.count - 1])
        }

        guard rotateMode.shouldRotate else {
            return .positionOnly(point: sampleAndRotation.point)
        }

        switch rotateMode {
        case .auto:
            if sampleAndRotation.direction == .zero {
                return .positionOnly(point: sampleAndRotation.point)
            }
            let radians: Double = atan2(
                Double(sampleAndRotation.direction.y),
                Double(sampleAndRotation.direction.x)
            )
            let degrees: Double = radians * 180 / .pi
            return .positionAndRotation(point: sampleAndRotation.point, rotationDegrees: degrees)
        case .autoReverse:
            if sampleAndRotation.direction == .zero {
                return .positionOnly(point: sampleAndRotation.point)
            }
            let radians: Double = atan2(
                Double(sampleAndRotation.direction.y),
                Double(sampleAndRotation.direction.x)
            )
            let degrees: Double = (radians * 180 / .pi) + 180
            return .positionAndRotation(point: sampleAndRotation.point, rotationDegrees: degrees)
        case .fixed(let angleDegrees):
            return .positionAndRotation(point: sampleAndRotation.point, rotationDegrees: angleDegrees)
        case .none:
            return .positionOnly(point: sampleAndRotation.point)
        }
    }

    private static func samplePoint(
        on points: [CGPoint],
        directions: [CGPoint],
        atLength targetLength: Double
    ) -> (point: CGPoint, direction: CGPoint)? {
        var cumulative: Double = 0
        if points.count < 2 {
            return points.first.map { point in
                let direction: CGPoint = if directions.isEmpty {
                    .zero
                } else {
                    directions[0]
                }
                return (point: point, direction: direction)
            }
        }

        for index in 0 ..< (points.count - 1) {
            let from = points[index]
            let to = points[index + 1]
            let dx: Double = Double(to.x - from.x)
            let dy: Double = Double(to.y - from.y)
            let segmentLength: Double = sqrt((dx * dx) + (dy * dy))
            if segmentLength <= 0 {
                continue
            }

            let next: Double = cumulative + segmentLength
            if targetLength <= next {
                let localLength: Double = targetLength - cumulative
                let ratio: Double = localLength / segmentLength
                let point: CGPoint = CGPoint(
                    x: Double(from.x) + (Double(to.x - from.x) * ratio),
                    y: Double(from.y) + (Double(to.y - from.y) * ratio)
                )
                let direction: CGPoint = if index < directions.count {
                    directions[index]
                } else {
                    .zero
                }
                return (point, direction)
            }
            cumulative = next
        }

        return (point: points[points.count - 1], direction: directions.last ?? .zero)
    }

    private static func motionPathLength(points: [CGPoint]) -> Double {
        guard points.count >= 2 else {
            return 0
        }

        var total: Double = 0
        for index in 0 ..< (points.count - 1) {
            let from = points[index]
            let to = points[index + 1]
            let dx: Double = Double(to.x - from.x)
            let dy: Double = Double(to.y - from.y)
            total += sqrt((dx * dx) + (dy * dy))
        }
        return total
    }

    private static func buildPathSamples(
        from commands: [SVGPathCommand],
        intoPoints points: inout [CGPoint],
        intoDirections directions: inout [CGPoint]
    ) {
        var currentPoint: CGPoint = .zero
        var subpathStart: CGPoint = .zero
        var lastCubicControl: CGPoint? = nil
        var lastQuadraticControl: CGPoint? = nil

        for command in commands {
            let symbol: Character = command.symbol
            let isRelative: Bool = symbol.isLowercase
            let key: Character = if isRelative {
                Character(String(symbol).uppercased())
            } else {
                symbol
            }
            let values: [Double] = command.values
            var index: Int = 0

            switch key {
            case "M":
                var isFirstMove: Bool = true
                while index + 1 < values.count {
                    let x: Double = values[index]
                    let y: Double = values[index + 1]
                    let next: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                    } else {
                        CGPoint(x: x, y: y)
                    }
                    if isFirstMove {
                        points.append(next)
                        subpathStart = next
                    } else {
                        appendLineSamples(
                            from: currentPoint,
                            to: next,
                            segments: motionPathCurveSegmentCount,
                            intoPoints: &points,
                            intoDirections: &directions
                        )
                    }
                    currentPoint = next
                    if isFirstMove {
                        subpathStart = next
                        isFirstMove = false
                    }
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                    index += 2
                }

            case "L":
                while index + 1 < values.count {
                    let x: Double = values[index]
                    let y: Double = values[index + 1]
                    let next: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                    } else {
                        CGPoint(x: x, y: y)
                    }
                    appendLineSamples(
                        from: currentPoint,
                        to: next,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = next
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                    index += 2
                }

            case "H":
                while index < values.count {
                    let next: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + values[index], y: currentPoint.y)
                    } else {
                        CGPoint(x: values[index], y: currentPoint.y)
                    }
                    appendLineSamples(
                        from: currentPoint,
                        to: next,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = next
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                    index += 1
                }

            case "V":
                while index < values.count {
                    let next: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x, y: currentPoint.y + values[index])
                    } else {
                        CGPoint(x: currentPoint.x, y: values[index])
                    }
                    appendLineSamples(
                        from: currentPoint,
                        to: next,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = next
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                    index += 1
                }

            case "C":
                while index + 5 < values.count {
                    let c1: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + values[index], y: currentPoint.y + values[index + 1])
                    } else {
                        CGPoint(x: values[index], y: values[index + 1])
                    }
                    let c2: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index + 2],
                            y: currentPoint.y + values[index + 3]
                        )
                    } else {
                        CGPoint(x: values[index + 2], y: values[index + 3])
                    }
                    let destination: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index + 4],
                            y: currentPoint.y + values[index + 5]
                        )
                    } else {
                        CGPoint(x: values[index + 4], y: values[index + 5])
                    }

                    appendCubicSamples(
                        from: currentPoint,
                        control1: c1,
                        control2: c2,
                        to: destination,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = destination
                    lastCubicControl = c2
                    lastQuadraticControl = nil
                    index += 6
                }

            case "S":
                while index + 3 < values.count {
                    let reflected: CGPoint = if let last = lastCubicControl {
                        CGPoint(
                            x: currentPoint.x - (last.x - currentPoint.x),
                            y: currentPoint.y - (last.y - currentPoint.y)
                        )
                    } else {
                        currentPoint
                    }
                    let c2: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + values[index], y: currentPoint.y + values[index + 1])
                    } else {
                        CGPoint(x: values[index], y: values[index + 1])
                    }
                    let destination: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index + 2],
                            y: currentPoint.y + values[index + 3]
                        )
                    } else {
                        CGPoint(x: values[index + 2], y: values[index + 3])
                    }
                    appendCubicSamples(
                        from: currentPoint,
                        control1: reflected,
                        control2: c2,
                        to: destination,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = destination
                    lastCubicControl = c2
                    lastQuadraticControl = nil
                    index += 4
                }

            case "Q":
                while index + 3 < values.count {
                    let c: CGPoint = if isRelative {
                        CGPoint(x: currentPoint.x + values[index], y: currentPoint.y + values[index + 1])
                    } else {
                        CGPoint(x: values[index], y: values[index + 1])
                    }
                    let destination: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index + 2],
                            y: currentPoint.y + values[index + 3]
                        )
                    } else {
                        CGPoint(x: values[index + 2], y: values[index + 3])
                    }
                    appendQuadraticSamples(
                        from: currentPoint,
                        control: c,
                        to: destination,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = destination
                    lastQuadraticControl = c
                    lastCubicControl = nil
                    index += 4
                }

            case "T":
                while index + 1 < values.count {
                    let control: CGPoint = if let last = lastQuadraticControl {
                        CGPoint(
                            x: currentPoint.x - (last.x - currentPoint.x),
                            y: currentPoint.y - (last.y - currentPoint.y)
                        )
                    } else {
                        currentPoint
                    }
                    let destination: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index],
                            y: currentPoint.y + values[index + 1]
                        )
                    } else {
                        CGPoint(x: values[index], y: values[index + 1])
                    }
                    appendQuadraticSamples(
                        from: currentPoint,
                        control: control,
                        to: destination,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = destination
                    lastQuadraticControl = control
                    lastCubicControl = nil
                    index += 2
                }

            case "A":
                while index + 6 < values.count {
                    let destination: CGPoint = if isRelative {
                        CGPoint(
                            x: currentPoint.x + values[index + 5],
                            y: currentPoint.y + values[index + 6]
                        )
                    } else {
                        CGPoint(x: values[index + 5], y: values[index + 6])
                    }
                    appendLineSamples(
                        from: currentPoint,
                        to: destination,
                        segments: motionPathCurveSegmentCount,
                        intoPoints: &points,
                        intoDirections: &directions
                    )
                    currentPoint = destination
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                    index += 7
                }

            case "Z":
                appendLineSamples(
                    from: currentPoint,
                    to: subpathStart,
                    segments: motionPathCurveSegmentCount,
                    intoPoints: &points,
                    intoDirections: &directions
                )
                currentPoint = subpathStart
                lastCubicControl = nil
                lastQuadraticControl = nil

            default:
                continue
            }
        }
    }

    private static func appendLineSamples(
        from start: CGPoint,
        to end: CGPoint,
        segments: Int,
        intoPoints points: inout [CGPoint],
        intoDirections directions: inout [CGPoint]
    ) {
        let segmentCount = max(segments, 1)
        if points.isEmpty {
            points.append(start)
        }

        for step in 1...segmentCount {
            let ratio: Double = Double(step) / Double(segmentCount)
            let point: CGPoint = CGPoint(
                x: Double(start.x) + (Double(end.x - start.x) * ratio),
                y: Double(start.y) + (Double(end.y - start.y) * ratio)
            )
            points.append(point)
        }
        if segmentCount > 0 {
            let dx = end.x - start.x
            let dy = end.y - start.y
            let direction: CGPoint = CGPoint(x: dx, y: dy)
            let directionCount: Int = points.count - 1
            if directionCount > 0 {
                directions.append(contentsOf: Array(repeating: direction, count: segmentCount))
            }
        }
    }

    private static func appendCubicSamples(
        from start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        to end: CGPoint,
        segments: Int,
        intoPoints points: inout [CGPoint],
        intoDirections directions: inout [CGPoint]
    ) {
        if points.isEmpty {
            points.append(start)
        }
        let segmentCount = max(segments, 1)
        for step in 1...segmentCount {
            let t: Double = Double(step) / Double(segmentCount)
            let oneMinusT: Double = 1 - t
            let x1 = oneMinusT * oneMinusT * oneMinusT * Double(start.x)
                + 3 * oneMinusT * oneMinusT * t * Double(control1.x)
                + 3 * oneMinusT * t * t * Double(control2.x)
                + t * t * t * Double(end.x)
            let y1 = oneMinusT * oneMinusT * oneMinusT * Double(start.y)
                + 3 * oneMinusT * oneMinusT * t * Double(control1.y)
                + 3 * oneMinusT * t * t * Double(control2.y)
                + t * t * t * Double(end.y)
            let point = CGPoint(x: x1, y: y1)
            points.append(point)

            let tangentX = (
                -3 * oneMinusT * oneMinusT * Double(start.x)
                + (3 * oneMinusT * oneMinusT - 6 * oneMinusT * t) * Double(control1.x)
                + (6 * oneMinusT * t - 3 * t * t) * Double(control2.x)
                + 3 * t * t * Double(end.x)
            )
            let tangentY = (
                -3 * oneMinusT * oneMinusT * Double(start.y)
                + (3 * oneMinusT * oneMinusT - 6 * oneMinusT * t) * Double(control1.y)
                + (6 * oneMinusT * t - 3 * t * t) * Double(control2.y)
                + 3 * t * t * Double(end.y)
            )
            directions.append(CGPoint(x: tangentX, y: tangentY))
        }
    }

    private static func appendQuadraticSamples(
        from start: CGPoint,
        control: CGPoint,
        to end: CGPoint,
        segments: Int,
        intoPoints points: inout [CGPoint],
        intoDirections directions: inout [CGPoint]
    ) {
        if points.isEmpty {
            points.append(start)
        }
        let segmentCount = max(segments, 1)
        for step in 1...segmentCount {
            let t: Double = Double(step) / Double(segmentCount)
            let oneMinusT: Double = 1 - t
            let x = oneMinusT * oneMinusT * Double(start.x)
                + 2 * oneMinusT * t * Double(control.x)
                + t * t * Double(end.x)
            let y = oneMinusT * oneMinusT * Double(start.y)
                + 2 * oneMinusT * t * Double(control.y)
                + t * t * Double(end.y)
            points.append(CGPoint(x: x, y: y))

            let tangentX = 2 * (oneMinusT * (Double(control.x - start.x)) + t * (Double(end.x - control.x)))
            let tangentY = 2 * (oneMinusT * (Double(control.y - start.y)) + t * (Double(end.y - control.y)))
            directions.append(CGPoint(x: tangentX, y: tangentY))
        }
    }

    private static func parseSMILPoint(_ raw: String?) -> CGPoint? {
        guard let raw else {
            return nil
        }
        let normalized: String = raw
            .replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = normalized
            .split { char in
                char == " "
                    || char == "\t"
                    || char == "\n"
                    || char == "\r"
            }
        if parts.count < 2 {
            return nil
        }

        guard let x = parseSMILDouble(String(parts[0])), let y = parseSMILDouble(String(parts[1])) else {
            return nil
        }

        let pointX: CGFloat = CGFloat(x)
        let pointY: CGFloat = CGFloat(y)
        return CGPoint(x: pointX, y: pointY)
    }

    private static func applySetValue(
        value: String?,
        into target: inout Double
    ) -> Bool {
        guard let next = value, let nextValue = parseSMILDouble(next) else {
            return false
        }
        target = nextValue
        return true
    }

    private static func samplePaintValue(
        baseValue: SVGPaint,
        animation: SVGSMILAnimation,
        elapsed: TimeInterval,
        sample: SVGSMILEngineTimelineSample
    ) -> SVGPaint? {
        let rawValues: [String] = parseAnimationValues(animation.values?.raw)
        if rawValues.count >= 2 {
            let paints = parsePaintValues(rawValues)
            guard paints.count >= 2 else {
                return nil
            }
            let timelineSample = timelineSample(
                for: animation.timing,
                elapsed: elapsed,
                valueCount: paints.count,
                interpolation: animation.interpolation,
                keyTimes: animation.keyTimes,
                keySplines: animation.keySplines,
                fillMode: animation.timing.fill
            ) ?? sample
            return interpolatePaint(
                paints,
                sample: timelineSample
            )
        }

        let progress: Double = sample.timelineProgress
        if let fromColor = parsePaint(animation.fromValue), let toColor = parsePaint(animation.toValue) {
            return interpolatePaint(fromColor, to: toColor, progress: progress)
        }
        if let toColor = parsePaint(animation.toValue) {
            if progress >= 1 {
                return toColor
            }
            return baseValue
        }
        return nil
    }

    private static func sampleNumericValue(
        from baseValue: Double,
        animation: SVGSMILAnimation,
        elapsed: TimeInterval,
        sample: SVGSMILEngineTimelineSample
    ) -> Double? {
        let rawValues: [String] = parseAnimationValues(animation.values?.raw)
        if rawValues.count >= 2 {
            let numbers = parseSMILNumbers(rawValues)
            if numbers.count >= 2 {
                let timelineSample = timelineSample(
                    for: animation.timing,
                    elapsed: elapsed,
                    valueCount: numbers.count,
                    interpolation: animation.interpolation,
                    keyTimes: animation.keyTimes,
                    keySplines: animation.keySplines,
                    fillMode: animation.timing.fill
                ) ?? sample
                return interpolateNumber(
                    values: numbers,
                    sample: timelineSample
                )
            }
        }
        let progress: Double = sample.timelineProgress
        let fromValue: Double = if let rawFrom = animation.fromValue {
            parseSMILDouble(rawFrom) ?? baseValue
        } else {
            baseValue
        }
        let targetValue: Double? = if animation.kind == .set {
            if let rawTo = animation.toValue {
                parseSMILDouble(rawTo)
            } else {
                nil
            }
        } else if let rawTo = animation.toValue {
            parseSMILDouble(rawTo)
        } else if let rawBy = animation.byValue, let byValue = parseSMILDouble(rawBy) {
            fromValue + byValue
        } else {
            nil
        }
        guard let to = targetValue else {
            return nil
        }
        return fromValue + (to - fromValue) * progress
    }

    private static func sampleTransformValue(
        baseValue: CGAffineTransform,
        animation: SVGSMILAnimation,
        elapsed: TimeInterval,
        sample: SVGSMILEngineTimelineSample
    ) -> CGAffineTransform? {
        let rawValues: [String] = parseAnimationValues(animation.values?.raw)
        if rawValues.count >= 2 {
            let values = parseTransformValues(
                rawValues,
                type: animation.type
            )
            if values.count >= 2 {
                let timelineSample = timelineSample(
                    for: animation.timing,
                    elapsed: elapsed,
                    valueCount: values.count,
                    interpolation: animation.interpolation,
                    keyTimes: animation.keyTimes,
                    keySplines: animation.keySplines,
                    fillMode: animation.timing.fill
                ) ?? sample
                return interpolateTransform(
                    values,
                    sample: timelineSample
                )
            }
        }

        let progress: Double = sample.timelineProgress
        if let from = parseTransformValue(
            animation.fromValue,
            type: animation.type
        ), let to = parseTransformValue(
            animation.toValue,
            type: animation.type
        ) {
            return interpolateTransform([from, to], progress: progress)
        }

        if animation.kind == .set, let to = parseTransformValue(animation.toValue, type: animation.type) {
            if progress < 1 {
                return baseValue
            }
            return to
        }

        if let to = parseTransformValue(animation.toValue, type: animation.type) {
            if progress >= 1 {
                return to
            }
            return baseValue
        }

        if let by = animation.byValue {
            let fromTransform: CGAffineTransform = parseTransformValue(
                animation.fromValue,
                type: animation.type
            ) ?? baseValue

            if let offset = parseTransformValue(by, type: animation.type) {
                return interpolateTransform(
                    [fromTransform, fromTransform.concatenating(offset)],
                    progress: progress
                )
            }
        }

        return nil
    }

    private static func interpolateTransform(
        _ transforms: [CGAffineTransform],
        sample: SVGSMILEngineTimelineSample
    ) -> CGAffineTransform {
        if sample.usesKeyTimes {
            let segmentIndex: Int = sample.segmentIndex
            let segmentCount: Int = max(transforms.count - 1, 0)
            if segmentCount == 0 {
                return transforms.first ?? .identity
            }
            let safeSegment: Int = min(segmentIndex, segmentCount - 1)
            return interpolateTransform(
                transforms[safeSegment],
                to: transforms[safeSegment + 1],
                progress: sample.segmentProgress
            )
        }
        return interpolateTransform(
            transforms,
            progress: sample.timelineProgress
        )
    }

    private static func interpolateTransform(
        _ transforms: [CGAffineTransform],
        progress: Double
    ) -> CGAffineTransform {
        guard !transforms.isEmpty else {
            return .identity
        }
        if transforms.count == 1 {
            return transforms[0]
        }
        if progress <= 0 {
            return transforms[0]
        }
        if progress >= 1 {
            return transforms[transforms.count - 1]
        }
        if transforms.count == 2 {
            return interpolateTransform(
                transforms[0],
                to: transforms[1],
                progress: progress
            )
        }
        let clampedProgress = clamp(progress, min: 0, max: 1)
        let scaled = clampedProgress * Double(transforms.count - 1)
        let segmentIndexCandidate = Int(scaled)
        let segmentIndex = min(segmentIndexCandidate, transforms.count - 2)
        let segmentStart = Double(segmentIndex)
        let localProgress = scaled - segmentStart
        return interpolateTransform(
            transforms[segmentIndex],
            to: transforms[segmentIndex + 1],
            progress: localProgress
        )
    }

    private static func interpolateTransform(
        _ from: CGAffineTransform,
        to: CGAffineTransform,
        progress: Double
    ) -> CGAffineTransform {
        let clampedProgress = clamp(progress, min: 0, max: 1)
        let fromValues = [from.a, from.b, from.c, from.d, from.tx, from.ty]
        let toValues = [to.a, to.b, to.c, to.d, to.tx, to.ty]
        return CGAffineTransform(
            a: CGFloat(interpolateTransformComponent(from: fromValues[0], to: toValues[0], progress: clampedProgress)),
            b: CGFloat(interpolateTransformComponent(from: fromValues[1], to: toValues[1], progress: clampedProgress)),
            c: CGFloat(interpolateTransformComponent(from: fromValues[2], to: toValues[2], progress: clampedProgress)),
            d: CGFloat(interpolateTransformComponent(from: fromValues[3], to: toValues[3], progress: clampedProgress)),
            tx: CGFloat(interpolateTransformComponent(from: fromValues[4], to: toValues[4], progress: clampedProgress)),
            ty: CGFloat(interpolateTransformComponent(from: fromValues[5], to: toValues[5], progress: clampedProgress))
        )
    }

    private static func interpolateTransformComponent(from: CGFloat, to: CGFloat, progress: Double) -> Double {
        return Double(from) + (Double(to) - Double(from)) * clamp(progress, min: 0, max: 1)
    }

    private static func parseTransformValues(
        _ values: [String],
        type: String?
    ) -> [CGAffineTransform] {
        var output: [CGAffineTransform] = []
        output.reserveCapacity(values.count)
        for value in values {
            guard let next = parseTransformValue(value, type: type) else {
                return []
            }
            output.append(next)
        }
        return output
    }

    private static func parseTransformValue(_ value: String?, type: String?) -> CGAffineTransform? {
        guard let rawValue = value else {
            return nil
        }
        let normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedValue.isEmpty {
            return nil
        }
        let normalizedType = type?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let explicitType = normalizedType, !explicitType.isEmpty {
            let numbers = parseTransformNumberList(explicitType == "matrix" ? 6 : 1, from: normalizedValue)
            if let transform = makeTransform(type: explicitType, values: numbers) {
                return transform
            }
            if normalizedValue.contains("(") && normalizedValue.contains(")") {
                return parseTransformFunctionList(normalizedValue)
            }
            return nil
        }

        if normalizedValue.contains("(") && normalizedValue.contains(")") {
            return parseTransformFunctionList(normalizedValue)
        }
        return nil
    }

    private static func parseTransformNumberList(_ expectedCount: Int, from value: String) -> [Double] {
        let normalized = value.replacingOccurrences(of: ",", with: " ")
        let parts = normalized
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" })
        let numbers = parts.compactMap { parseSMILDouble(String($0)) }
        if numbers.count >= expectedCount {
            return numbers
        }
        return []
    }

    private static func makeTransform(type: String, values: [Double]) -> CGAffineTransform? {
        switch type {
        case "matrix":
            guard values.count >= 6 else {
                return nil
            }
            return CGAffineTransform(
                a: values[0],
                b: values[1],
                c: values[2],
                d: values[3],
                tx: values[4],
                ty: values[5]
            )
        case "translate":
            guard !values.isEmpty else {
                return nil
            }
            let tx = values[0]
            let ty = values.count >= 2 ? values[1] : 0
            return CGAffineTransform(translationX: tx, y: ty)
        case "scale":
            guard !values.isEmpty else {
                return nil
            }
            let sx = values[0]
            let sy = values.count >= 2 ? values[1] : sx
            return CGAffineTransform(scaleX: sx, y: sy)
        case "rotate":
            guard !values.isEmpty else {
                return nil
            }
            let angle = values[0]
            if values.count >= 3 {
                return rotateAround(
                    angle: angle,
                    centerX: values[1],
                    centerY: values[2]
                )
            }
            return CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180))
        case "skewx":
            guard let angle = values.first else {
                return nil
            }
            let radians = angle * .pi / 180
            return CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(radians)), d: 1, tx: 0, ty: 0)
        case "skewy":
            guard let angle = values.first else {
                return nil
            }
            let radians = angle * .pi / 180
            return CGAffineTransform(a: 1, b: CGFloat(tan(radians)), c: 0, d: 1, tx: 0, ty: 0)
        case "transform":
            if values.count == 6 {
                return CGAffineTransform(
                    a: values[0],
                    b: values[1],
                    c: values[2],
                    d: values[3],
                    tx: values[4],
                    ty: values[5]
                )
            }
            return nil
        default:
            return nil
        }
    }

    private static func parseTransformFunctionList(_ value: String) -> CGAffineTransform? {
        let normalized = value.replacingOccurrences(of: ",", with: " ")
        let parts = normalized.split(separator: ")")
        guard !parts.isEmpty else {
            return nil
        }
        var result = CGAffineTransform.identity
        for part in parts {
            let token = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else {
                continue
            }
            guard let leftParen = token.firstIndex(of: "(") else {
                continue
            }
            let name = String(token[..<leftParen]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let values = String(token[token.index(after: leftParen)...])
            guard let transform = parseTransformValue(values, type: name) else {
                continue
            }
            result = result.concatenating(transform)
        }
        return result
    }

    private static func rotateAround(
        angle: Double,
        centerX: Double,
        centerY: Double
    ) -> CGAffineTransform {
        let radians = angle * .pi / 180
        var output = CGAffineTransform(translationX: centerX, y: centerY)
        output = output.rotated(by: CGFloat(radians))
        output = output.translatedBy(x: -centerX, y: -centerY)
        return output
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.min(Swift.max(value, min), max)
    }

    private static func timelineSample(
        for timing: SVGSMILAnimationTiming,
        elapsed: TimeInterval,
        valueCount: Int?,
        interpolation: SVGSMILAnimationValueInterpolation,
        keyTimes: String?,
        keySplines: String?,
        fillMode: SVGSMILAnimationFill
    ) -> SVGSMILEngineTimelineSample? {
        guard let progress = timelineProgress(
            for: timing,
            elapsed: elapsed,
            fillMode: fillMode
        ) else {
            return nil
        }

        guard
            let targetValueCount: Int = valueCount,
            targetValueCount >= 2,
            let keyTimesValue: String = keyTimes,
            let keyTimesProgress = applyKeyTimes(
                progress,
                targetValueCount: targetValueCount,
                keyTimes: keyTimesValue,
                interpolation: interpolation,
                keySplines: keySplines
            )
        else {
            return SVGSMILEngineTimelineSample(
                timelineProgress: progress,
                segmentProgress: progress,
                segmentIndex: 0,
                usesKeyTimes: false
            )
        }

        return keyTimesProgress
    }

    private static func timelineProgress(
        for timing: SVGSMILAnimationTiming,
        elapsed: TimeInterval,
        fillMode: SVGSMILAnimationFill
    ) -> Double? {
        let startDelay: Double = timing.begin.min() ?? 0
        let localElapsed: TimeInterval = elapsed - startDelay
        if localElapsed < 0 {
            return nil
        }
        guard let duration = timing.dur else {
            return fillMode == .remove && localElapsed >= 0 ? 1 : 1
        }
        if duration <= 0 {
            return fillMode == .remove ? 1 : 1
        }

        let repeatCount: Double = switch timing.repeatCount {
        case .none:
            1
        case .indefinite:
            Double.greatestFiniteMagnitude
        case .finite(let value):
            value
        }
        if repeatCount <= 0 {
            return nil
        }
        let totalDuration: Double = duration * repeatCount
        if localElapsed >= totalDuration {
            if fillMode != .freeze {
                return nil
            }
            return 1
        }
        let cycleElapsed: TimeInterval = localElapsed.truncatingRemainder(dividingBy: duration)
        let progress: Double = cycleElapsed / duration
        if progress < 0 {
            return nil
        }
        if progress >= 1 {
            return 1
        }
        return progress
    }

    private static func applyKeyTimes(
        _ progress: Double,
        targetValueCount: Int,
        keyTimes: String,
        interpolation: SVGSMILAnimationValueInterpolation,
        keySplines: String?
    ) -> SVGSMILEngineTimelineSample? {
        let times: [Double] = parseSMILKeyTimes(keyTimes)
        if times.count != targetValueCount {
            return nil
        }
        if times.count < 2 {
            return nil
        }
        let firstValue: Double = times.first ?? 0
        let lastValue: Double = times.last ?? 1
        if firstValue > 0 || lastValue < 1 {
            return nil
        }

        let clampedProgress: Double = clamp(progress, min: 0, max: 1)
        if clampedProgress <= 0 {
            return SVGSMILEngineTimelineSample(
                timelineProgress: clampedProgress,
                segmentProgress: 0,
                segmentIndex: 0,
                usesKeyTimes: true
            )
        }
        if clampedProgress >= 1 {
            return SVGSMILEngineTimelineSample(
                timelineProgress: clampedProgress,
                segmentProgress: 1,
                segmentIndex: times.count - 2,
                usesKeyTimes: true
            )
        }

        for segmentIndex in 0 ..< (times.count - 1) {
            let segmentStart: Double = times[segmentIndex]
            let segmentEnd: Double = times[segmentIndex + 1]
            if clampedProgress < segmentStart || clampedProgress > segmentEnd {
                continue
            }

            let segmentLength: Double = segmentEnd - segmentStart
            let segmentRange: Double = segmentLength == 0 ? 0 : (clampedProgress - segmentStart) / segmentLength
            let rawSegmentProgress: Double = clamp(segmentRange, min: 0, max: 1)
            let adjustedProgress: Double = applyKeySpline(
                to: rawSegmentProgress,
                segmentIndex: segmentIndex,
                interpolation: interpolation,
                keySplines: keySplines
            )
            return SVGSMILEngineTimelineSample(
                timelineProgress: clampedProgress,
                segmentProgress: adjustedProgress,
                segmentIndex: segmentIndex,
                usesKeyTimes: true
            )
        }

        return SVGSMILEngineTimelineSample(
            timelineProgress: clampedProgress,
            segmentProgress: clampedProgress,
            segmentIndex: 0,
            usesKeyTimes: false
        )
    }

    private static func applyKeySpline(
        to progress: Double,
        segmentIndex: Int,
        interpolation: SVGSMILAnimationValueInterpolation,
        keySplines: String?
    ) -> Double {
        let trimmedInterpolation: SVGSMILAnimationValueInterpolation = interpolation
        if trimmedInterpolation != .spline {
            return progress
        }
        guard let keySplinesValue = keySplines else {
            return progress
        }
        let points: [Double] = parseKeySplines(keySplinesValue)
        let splineIndex: Int = segmentIndex * 4
        let splineCount = points.count / 4
        if splineIndex < 0 || splineIndex + 3 >= points.count || splineCount <= segmentIndex {
            return progress
        }
        let x1: Double = points[splineIndex]
        let y1: Double = points[splineIndex + 1]
        let x2: Double = points[splineIndex + 2]
        let y2: Double = points[splineIndex + 3]
        let safeProgress: Double = clamp(progress, min: 0, max: 1)
        return cubicBezier(progress: safeProgress, x1: x1, y1: y1, x2: x2, y2: y2)
    }

    private static func parseSMILKeyTimes(_ raw: String) -> [Double] {
        let values: [String] = raw
            .split(separator: ";")
            .map { value in
                value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        return values.compactMap { parseSMILDouble($0) }
    }

    private static func parseKeySplines(_ raw: String) -> [Double] {
        let values: [String] = raw
            .split(separator: ";")
            .flatMap { segment in
                segment
                    .split(whereSeparator: { character in
                        character == " " || character == "\t" || character == "\n" || character == "\r" || character == ","
                    })
                    .map { value in
                        value.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
            }
            .filter { !$0.isEmpty }
        return values.compactMap { parseSMILDouble($0) }
    }

    private static func cubicBezier(
        progress: Double,
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double
    ) -> Double {
        let clampedProgress: Double = clamp(progress, min: 0, max: 1)
        if clampedProgress <= 0 || clampedProgress >= 1 {
            return clampedProgress
        }

        var t: Double = clampedProgress
        for _ in 0..<8 {
            let x: Double = cubicBezierPoint(p0: 0, p1: x1, p2: x2, p3: 1, t: t)
            let derivativeX: Double = cubicBezierDerivative(p0: 0, p1: x1, p2: x2, p3: 1, t: t)
            if abs(derivativeX) < 1e-6 {
                break
            }
            t = t - (x - clampedProgress) / derivativeX
            t = clamp(t, min: 0, max: 1)
        }

        return cubicBezierPoint(p0: 0, p1: y1, p2: y2, p3: 1, t: t)
    }

    private static func cubicBezierPoint(
        p0: Double,
        p1: Double,
        p2: Double,
        p3: Double,
        t: Double
    ) -> Double {
        let oneMinusT: Double = 1 - t
        return
            p0 * (oneMinusT * oneMinusT * oneMinusT) +
            3 * p1 * oneMinusT * oneMinusT * t +
            3 * p2 * oneMinusT * t * t +
            p3 * t * t * t
    }

    private static func cubicBezierDerivative(
        p0: Double,
        p1: Double,
        p2: Double,
        p3: Double,
        t: Double
    ) -> Double {
        let oneMinusT: Double = 1 - t
        return
            3 * (p1 - p0) * oneMinusT * oneMinusT +
            6 * (p2 - p1) * oneMinusT * t +
            3 * (p3 - p2) * t * t
    }

    private static func interpolatePaint(
        _ paints: [SVGPaint],
        sample: SVGSMILEngineTimelineSample
    ) -> SVGPaint? {
        if sample.usesKeyTimes {
            let segmentIndex: Int = sample.segmentIndex
            let segmentCount: Int = max(paints.count - 1, 0)
            if segmentCount == 0 {
                return paints.first
            }
            let safeIndex: Int = min(segmentIndex, segmentCount - 1)
            guard safeIndex + 1 < paints.count else {
                return paints.last
            }
            guard let fromColor = toColor(paints[safeIndex]),
                  let toColor = toColor(paints[safeIndex + 1]) else {
                return paints[safeIndex]
            }
            return interpolateColor(fromColor, to: toColor, progress: sample.segmentProgress)
        }
        return interpolatePaint(
            paints,
            progress: sample.timelineProgress
        )
    }

    private static func interpolatePaint(
        _ paints: [SVGPaint],
        progress: Double
    ) -> SVGPaint? {
        guard let first = paints.first else {
            return nil
        }
        if paints.count == 1 {
            return first
        }
        if progress >= 1 {
            return paints.last
        }
        if progress <= 0 {
            return paints.first
        }

        let maxSegmentIndex = max(paints.count - 2, 0)
        let scaled: Double = progress * Double(paints.count - 1)
        let segmentIndexCandidate: Int = Int(scaled)
        let segmentIndex = min(segmentIndexCandidate, maxSegmentIndex)
        guard
            let fromColor = toColor(paints[segmentIndex]),
            let toColor = toColor(paints[segmentIndex + 1])
        else {
            return paints[segmentIndex]
        }
        let segmentStart: Double = Double(segmentIndex)
        let segmentProgress: Double = (scaled - segmentStart)
                return interpolateColor(fromColor, to: toColor, progress: segmentProgress)
    }

    private static func interpolatePaint(
        _ from: SVGPaint,
        to: SVGPaint,
        progress: Double
    ) -> SVGPaint? {
        guard let fromColor = toColor(from), let toColor = toColor(to) else {
            return to
        }
        if progress <= 0 {
            return from
        }
        if progress >= 1 {
            return to
        }
        return interpolateColor(fromColor, to: toColor, progress: progress)
    }

    private static func toColor(_ paint: SVGPaint) -> SVGColor? {
        if case .color(let color) = paint {
            return color
        }
        return nil
    }

    private static func interpolateColor(_ from: SVGColor, to: SVGColor, progress: Double) -> SVGPaint {
        let clampedProgress: Double = max(min(progress, 1), 0)
        let red = from.red + (to.red - from.red) * clampedProgress
        let green = from.green + (to.green - from.green) * clampedProgress
        let blue = from.blue + (to.blue - from.blue) * clampedProgress
        let alpha = from.alpha + (to.alpha - from.alpha) * clampedProgress
        return .color(.init(red: red, green: green, blue: blue, alpha: alpha))
    }

    private static func interpolateNumber(
        values: [Double],
        sample: SVGSMILEngineTimelineSample
    ) -> Double {
        if sample.usesKeyTimes {
            let segmentCount: Int = max(values.count - 1, 0)
            if segmentCount == 0 {
                return values.first ?? 0
            }
            let safeSegment: Int = min(sample.segmentIndex, segmentCount - 1)
            let fromValue: Double = values[safeSegment]
            let toValue: Double = values[min(safeSegment + 1, values.count - 1)]
            return fromValue + (toValue - fromValue) * sample.segmentProgress
        }

        return interpolateNumber(values: values, progress: sample.timelineProgress)
    }

    private static func interpolateNumber(values: [Double], progress: Double) -> Double {
        if values.count == 1 {
            return values[0]
        }
        let clampedProgress: Double = max(min(progress, 1), 0)
        if clampedProgress >= 1 {
            return values[values.count - 1]
        }
        let maxSegment: Int = values.count - 1
        if maxSegment <= 0 {
            return values[0]
        }
        let scaled: Double = clampedProgress * Double(maxSegment)
        let segmentIndex: Int = min(Int(scaled), maxSegment - 1)
        let left = values[segmentIndex]
        let right = values[segmentIndex + 1]
        let segmentStart = Double(segmentIndex)
        let local = scaled - segmentStart
        return left + (right - left) * local
    }

    private static func parseAnimationValues(_ value: String?) -> [String] {
        guard let raw = value else {
            return []
        }
        let trimmed: String = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }
        return trimmed
            .split(separator: ";")
            .map { value in
                value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    private static func parseSMILNumbers(_ values: [String]) -> [Double] {
        var result: [Double] = []
        result.reserveCapacity(values.count)
        for value in values {
            if let parsed = parseSMILDouble(value) {
                result.append(parsed)
            }
        }
        return result
    }

    private static func parsePaintValues(_ values: [String]) -> [SVGPaint] {
        var paints: [SVGPaint] = []
        paints.reserveCapacity(values.count)
        for value in values {
            if let paint = parsePaint(value) {
                paints.append(paint)
            }
        }
        return paints
    }

    private static func parseSMILDouble(_ value: String) -> Double? {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if trimmed.hasSuffix("ms") {
            let numberText = String(trimmed.dropLast(2))
            guard let number = Double(numberText) else {
                return nil
            }
            return number / millisecondsPerSecond
        }
        if trimmed.hasSuffix("s") {
            let numberText = String(trimmed.dropLast(1))
            return Double(numberText)
        }
        if trimmed.hasSuffix("px") {
            let numberText = String(trimmed.dropLast(2))
            return Double(numberText)
        }
        if trimmed.hasSuffix("%") {
            let numberText = String(trimmed.dropLast(1))
            return Double(numberText)
        }
        return Double(trimmed)
    }

    private static func parsePaint(_ value: String?) -> SVGPaint? {
        guard let rawValue = value else {
            return nil
        }
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if normalized == "none" {
            return SVGPaint.none
        }
        if normalized == "currentcolor" {
            return SVGPaint.currentColor
        }
        if let hexColor = parseHexColor(normalized) {
            return .color(hexColor)
        }
        if let rgbColor = parseRGBColor(normalized) {
            return .color(rgbColor)
        }
        if let namedColor = parseNamedColor(normalized) {
            return .color(namedColor)
        }
        return nil
    }

    private static func parseHexColor(_ value: String) -> SVGColor? {
        guard value.hasPrefix("#") else {
            return nil
        }
        let hex = String(value.dropFirst())
        if hex.count == 3 {
            let expanded = String(hex.flatMap { [$0, $0] })
            return parseHexColor("#\(expanded)")
        }
        guard hex.count == 6 else {
            return nil
        }
        guard let intValue = Int(hex, radix: 16) else {
            return nil
        }
        let red: Double = Double((intValue >> 16) & 0xFF) / 255.0
        let green: Double = Double((intValue >> 8) & 0xFF) / 255.0
        let blue: Double = Double(intValue & 0xFF) / 255.0
        return SVGColor(
            red: red,
            green: green,
            blue: blue,
            alpha: 1
        )
    }

    private static func parseRGBColor(_ value: String) -> SVGColor? {
        guard value.hasPrefix("rgb("), value.hasSuffix(")") else {
            return nil
        }
        let startIndex: String.Index = value.index(value.startIndex, offsetBy: 4)
        let endIndex: String.Index = value.index(before: value.endIndex)
        let body = value[startIndex..<endIndex]
        let parts = body.split(separator: ",")
        if parts.count != 3 {
            return nil
        }
        let rawRed = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let rawGreen = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        let rawBlue = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let red = Double(rawRed),
            let green = Double(rawGreen),
            let blue = Double(rawBlue)
        else {
            return nil
        }
        return SVGColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }

    private static func parseNamedColor(_ value: String) -> SVGColor? {
        switch value {
        case "black":
            return SVGColor(red: 0, green: 0, blue: 0, alpha: 1)
        case "white":
            return SVGColor(red: 1, green: 1, blue: 1, alpha: 1)
        case "red":
            return SVGColor(red: 1, green: 0, blue: 0, alpha: 1)
        case "green":
            return SVGColor(red: 0, green: 1, blue: 0, alpha: 1)
        case "blue":
            return SVGColor(red: 0, green: 0, blue: 1, alpha: 1)
        default:
            return nil
        }
    }
}
