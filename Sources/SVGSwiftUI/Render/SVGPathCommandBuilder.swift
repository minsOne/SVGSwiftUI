import CoreGraphics
import Foundation

struct SVGPathCommandBuilder: Sendable {
    init() {}

    func buildPath(commands: [SVGPathCommand]) -> CGPath {
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
        let two: CGFloat = 2
        let reflectedX: CGFloat = (two * origin.x) - control.x
        let reflectedY: CGFloat = (two * origin.y) - control.y
        return CGPoint(x: reflectedX, y: reflectedY)
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

        let startX: Double = Double(start.x)
        let startY: Double = Double(start.y)
        let endX: Double = Double(end.x)
        let endY: Double = Double(end.y)

        let phi: Double = xAxisRotation * (.pi / 180.0)
        let cosPhi: Double = cos(phi)
        let sinPhi: Double = sin(phi)

        let dx2: Double = (startX - endX) / 2.0
        let dy2: Double = (startY - endY) / 2.0
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        var lambda: Double = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let scale: Double = sqrt(lambda)
            rx *= scale
            ry *= scale
            lambda = 1
        }

        let sign: Double = (largeArc == sweep) ? -1.0 : 1.0
        let numerator: Double = max(0.0, rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p)
        let denominator: Double = max(Double.leastNonzeroMagnitude, rx * rx * y1p * y1p + ry * ry * x1p * x1p)
        let coefficient: Double = sign * sqrt(numerator / denominator)
        let cxp: Double = coefficient * (rx * y1p / ry)
        let cyp: Double = coefficient * (-ry * x1p / rx)

        let cx: Double = cosPhi * cxp - sinPhi * cyp + ((startX + endX) / 2.0)
        let cy: Double = sinPhi * cxp + cosPhi * cyp + ((startY + endY) / 2.0)

        let u = makePoint(x: (x1p - cxp) / rx, y: (y1p - cyp) / ry)
        let v = makePoint(x: (-x1p - cxp) / rx, y: (-y1p - cyp) / ry)

        var theta1 = angle(from: CGPoint(x: 1, y: 0), to: u)
        var deltaTheta = angle(from: u, to: v)

        if !sweep && deltaTheta > 0 {
            deltaTheta -= 2 * .pi
        } else if sweep && deltaTheta < 0 {
            deltaTheta += 2 * .pi
        }

        let segmentDivisor: Double = .pi / 2.0
        let segments: Int = max(1, Int(ceil(abs(deltaTheta) / segmentDivisor)))
        let delta: Double = deltaTheta / Double(segments)

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
        let alpha: Double = (4.0 / 3.0) * tan((t2 - t1) / 4.0)

        let cosT1: Double = cos(t1)
        let sinT1: Double = sin(t1)
        let cosT2: Double = cos(t2)
        let sinT2: Double = sin(t2)

        let p0 = makePoint(x: cosT1, y: sinT1)
        let p1 = makePoint(x: cosT1 - alpha * sinT1, y: sinT1 + alpha * cosT1)
        let p2 = makePoint(x: cosT2 + alpha * sinT2, y: sinT2 - alpha * cosT2)
        let p3 = makePoint(x: cosT2, y: sinT2)

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
        let x: Double = Double(point.x)
        let y: Double = Double(point.y)
        let transformedX: Double = cx + rx * x * cosPhi - ry * y * sinPhi
        let transformedY: Double = cy + rx * x * sinPhi + ry * y * cosPhi
        return makePoint(x: transformedX, y: transformedY)
    }

    private func angle(from u: CGPoint, to v: CGPoint) -> Double {
        let ux: Double = Double(u.x)
        let uy: Double = Double(u.y)
        let vx: Double = Double(v.x)
        let vy: Double = Double(v.y)
        let dot: Double = ux * vx + uy * vy
        let cross: Double = ux * vy - uy * vx
        return atan2(cross, dot)
    }

    private func makePoint(x: Double, y: Double) -> CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
