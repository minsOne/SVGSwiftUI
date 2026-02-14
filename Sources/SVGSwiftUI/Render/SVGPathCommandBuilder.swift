import CoreGraphics
import Foundation

public struct SVGPathCommandBuilder: Sendable {
    public init() {}

    public func buildPath(commands: [SVGPathCommand]) -> CGPath {
        let path = CGMutablePath()

        var currentPoint = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadraticControl: CGPoint?

        for command in commands {
            let symbol = command.symbol
            let values = command.values

            switch symbol {
            case "M", "m":
                let chunks = chunk(values, size: 2)
                for (index, pair) in chunks.enumerated() {
                    let x = CGFloat(pair[0])
                    let y = CGFloat(pair[1])
                    let point = symbol == "m"
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)
                    if index == 0 {
                        path.move(to: point)
                        subpathStart = point
                    } else {
                        path.addLine(to: point)
                    }
                    currentPoint = point
                }
                lastCubicControl = nil
                lastQuadraticControl = nil

            case "L", "l":
                let chunks = chunk(values, size: 2)
                for pair in chunks {
                    let x = CGFloat(pair[0])
                    let y = CGFloat(pair[1])
                    let point = symbol == "l"
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)
                    path.addLine(to: point)
                    currentPoint = point
                }
                lastCubicControl = nil
                lastQuadraticControl = nil

            case "H", "h":
                for value in values {
                    let x = CGFloat(value)
                    let point = symbol == "h"
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y)
                        : CGPoint(x: x, y: currentPoint.y)
                    path.addLine(to: point)
                    currentPoint = point
                }
                lastCubicControl = nil
                lastQuadraticControl = nil

            case "V", "v":
                for value in values {
                    let y = CGFloat(value)
                    let point = symbol == "v"
                        ? CGPoint(x: currentPoint.x, y: currentPoint.y + y)
                        : CGPoint(x: currentPoint.x, y: y)
                    path.addLine(to: point)
                    currentPoint = point
                }
                lastCubicControl = nil
                lastQuadraticControl = nil

            case "C", "c":
                let chunks = chunk(values, size: 6)
                for chunkValues in chunks {
                    let p1 = point(chunkValues[0], chunkValues[1], relative: symbol == "c", base: currentPoint)
                    let p2 = point(chunkValues[2], chunkValues[3], relative: symbol == "c", base: currentPoint)
                    let end = point(chunkValues[4], chunkValues[5], relative: symbol == "c", base: currentPoint)
                    path.addCurve(to: end, control1: p1, control2: p2)
                    currentPoint = end
                    lastCubicControl = p2
                    lastQuadraticControl = nil
                }

            case "S", "s":
                let chunks = chunk(values, size: 4)
                for chunkValues in chunks {
                    let c1 = reflectedPoint(of: lastCubicControl, around: currentPoint)
                    let c2 = point(chunkValues[0], chunkValues[1], relative: symbol == "s", base: currentPoint)
                    let end = point(chunkValues[2], chunkValues[3], relative: symbol == "s", base: currentPoint)
                    path.addCurve(to: end, control1: c1, control2: c2)
                    currentPoint = end
                    lastCubicControl = c2
                    lastQuadraticControl = nil
                }

            case "Q", "q":
                let chunks = chunk(values, size: 4)
                for chunkValues in chunks {
                    let control = point(chunkValues[0], chunkValues[1], relative: symbol == "q", base: currentPoint)
                    let end = point(chunkValues[2], chunkValues[3], relative: symbol == "q", base: currentPoint)
                    path.addQuadCurve(to: end, control: control)
                    currentPoint = end
                    lastQuadraticControl = control
                    lastCubicControl = nil
                }

            case "T", "t":
                let chunks = chunk(values, size: 2)
                for chunkValues in chunks {
                    let control = reflectedPoint(of: lastQuadraticControl, around: currentPoint)
                    let end = point(chunkValues[0], chunkValues[1], relative: symbol == "t", base: currentPoint)
                    path.addQuadCurve(to: end, control: control)
                    currentPoint = end
                    lastQuadraticControl = control
                    lastCubicControl = nil
                }

            case "A", "a":
                let chunks = chunk(values, size: 7)
                for chunkValues in chunks {
                    let rx = chunkValues[0]
                    let ry = chunkValues[1]
                    let xAxisRotation = chunkValues[2]
                    let largeArcFlag = chunkValues[3] != 0
                    let sweepFlag = chunkValues[4] != 0
                    let end = point(chunkValues[5], chunkValues[6], relative: symbol == "a", base: currentPoint)
                    addArc(
                        to: path,
                        from: currentPoint,
                        to: end,
                        rx: rx,
                        ry: ry,
                        xAxisRotation: xAxisRotation,
                        largeArc: largeArcFlag,
                        sweep: sweepFlag
                    )
                    currentPoint = end
                    lastCubicControl = nil
                    lastQuadraticControl = nil
                }

            case "Z", "z":
                path.closeSubpath()
                currentPoint = subpathStart
                lastCubicControl = nil
                lastQuadraticControl = nil

            default:
                continue
            }
        }

        return path
    }

    private func chunk(_ values: [Double], size: Int) -> [[Double]] {
        guard size > 0 else { return [] }
        var result: [[Double]] = []
        var index = 0
        while index + size <= values.count {
            result.append(Array(values[index..<(index + size)]))
            index += size
        }
        return result
    }

    private func point(_ x: Double, _ y: Double, relative: Bool, base: CGPoint) -> CGPoint {
        let px = CGFloat(x)
        let py = CGFloat(y)
        if relative {
            return CGPoint(x: base.x + px, y: base.y + py)
        }
        return CGPoint(x: px, y: py)
    }

    private func reflectedPoint(of control: CGPoint?, around origin: CGPoint) -> CGPoint {
        guard let control else {
            return origin
        }
        return CGPoint(x: 2 * origin.x - control.x, y: 2 * origin.y - control.y)
    }

    private func addArc(
        to path: CGMutablePath,
        from start: CGPoint,
        to end: CGPoint,
        rx: Double,
        ry: Double,
        xAxisRotation: Double,
        largeArc: Bool,
        sweep: Bool
    ) {
        var rx = abs(rx)
        var ry = abs(ry)
        guard rx > 0, ry > 0 else {
            path.addLine(to: end)
            return
        }
        if start == end {
            return
        }

        let phi = xAxisRotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx2 = Double(start.x - end.x) / 2
        let dy2 = Double(start.y - end.y) / 2
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        var lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let scale = sqrt(lambda)
            rx *= scale
            ry *= scale
            lambda = 1
        }

        let sign = (largeArc == sweep) ? -1.0 : 1.0
        let numerator = max(0, rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p)
        let denominator = max(Double.leastNonzeroMagnitude, rx * rx * y1p * y1p + ry * ry * x1p * x1p)
        let coefficient = sign * sqrt(numerator / denominator)
        let cxp = coefficient * (rx * y1p / ry)
        let cyp = coefficient * (-ry * x1p / rx)

        let cx = cosPhi * cxp - sinPhi * cyp + Double(start.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + Double(start.y + end.y) / 2

        let u = CGPoint(x: (x1p - cxp) / rx, y: (y1p - cyp) / ry)
        let v = CGPoint(x: (-x1p - cxp) / rx, y: (-y1p - cyp) / ry)

        var theta1 = angle(from: CGPoint(x: 1, y: 0), to: u)
        var deltaTheta = angle(from: u, to: v)

        if !sweep && deltaTheta > 0 {
            deltaTheta -= 2 * .pi
        } else if sweep && deltaTheta < 0 {
            deltaTheta += 2 * .pi
        }

        let segments = max(1, Int(ceil(abs(deltaTheta) / (.pi / 2))))
        let delta = deltaTheta / Double(segments)

        for _ in 0..<segments {
            let t1 = theta1
            let t2 = t1 + delta
            addArcSegment(
                to: path,
                cx: cx,
                cy: cy,
                rx: rx,
                ry: ry,
                cosPhi: cosPhi,
                sinPhi: sinPhi,
                t1: t1,
                t2: t2
            )
            theta1 = t2
        }
    }

    private func addArcSegment(
        to path: CGMutablePath,
        cx: Double,
        cy: Double,
        rx: Double,
        ry: Double,
        cosPhi: Double,
        sinPhi: Double,
        t1: Double,
        t2: Double
    ) {
        let alpha = 4.0 / 3.0 * tan((t2 - t1) / 4.0)
        let p0 = CGPoint(x: cos(t1), y: sin(t1))
        let p1 = CGPoint(x: cos(t1) - alpha * sin(t1), y: sin(t1) + alpha * cos(t1))
        let p2 = CGPoint(x: cos(t2) + alpha * sin(t2), y: sin(t2) - alpha * cos(t2))
        let p3 = CGPoint(x: cos(t2), y: sin(t2))

        let c1 = mapEllipsePoint(p1, cx: cx, cy: cy, rx: rx, ry: ry, cosPhi: cosPhi, sinPhi: sinPhi)
        let c2 = mapEllipsePoint(p2, cx: cx, cy: cy, rx: rx, ry: ry, cosPhi: cosPhi, sinPhi: sinPhi)
        let end = mapEllipsePoint(p3, cx: cx, cy: cy, rx: rx, ry: ry, cosPhi: cosPhi, sinPhi: sinPhi)

        _ = p0 // keep derivation explicit for readability
        path.addCurve(to: end, control1: c1, control2: c2)
    }

    private func mapEllipsePoint(
        _ point: CGPoint,
        cx: Double,
        cy: Double,
        rx: Double,
        ry: Double,
        cosPhi: Double,
        sinPhi: Double
    ) -> CGPoint {
        let x = Double(point.x)
        let y = Double(point.y)
        let transformedX = cx + rx * x * cosPhi - ry * y * sinPhi
        let transformedY = cy + rx * x * sinPhi + ry * y * cosPhi
        return CGPoint(x: transformedX, y: transformedY)
    }

    private func angle(from u: CGPoint, to v: CGPoint) -> Double {
        let dot = Double(u.x * v.x + u.y * v.y)
        let cross = Double(u.x * v.y - u.y * v.x)
        return atan2(cross, dot)
    }
}
