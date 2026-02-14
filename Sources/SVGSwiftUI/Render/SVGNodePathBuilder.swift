import CoreGraphics

public struct SVGNodePathBuilder: Sendable {
    private let commandBuilder = SVGPathCommandBuilder()
    private let pathDataParser = SVGPathDataParser()

    public init() {}

    public func buildPath(for node: SVGNode) -> CGPath? {
        switch node {
        case .group:
            return nil
        case .path(let pathNode):
            return buildPathPath(pathNode)
        case .shape(let shapeNode):
            return buildShapePath(shapeNode)
        }
    }

    private func buildPathPath(_ node: SVGPathNode) -> CGPath {
        let commands: [SVGPathCommand]
        if !node.commands.isEmpty {
            commands = node.commands
        } else if !node.pathData.isEmpty, let parsed = try? pathDataParser.parse(node.pathData) {
            commands = parsed
        } else {
            commands = []
        }
        return commandBuilder.buildPath(commands: commands)
    }

    private func buildShapePath(_ node: SVGShapeNode) -> CGPath {
        let path = CGMutablePath()
        switch node.kind {
        case .rect:
            let x = CGFloat(node.values["x"] ?? 0)
            let y = CGFloat(node.values["y"] ?? 0)
            let width = CGFloat(node.values["width"] ?? 0)
            let height = CGFloat(node.values["height"] ?? 0)
            path.addRect(CGRect(x: x, y: y, width: width, height: height))

        case .circle:
            let cx = CGFloat(node.values["cx"] ?? 0)
            let cy = CGFloat(node.values["cy"] ?? 0)
            let r = CGFloat(node.values["r"] ?? 0)
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))

        case .ellipse:
            let cx = CGFloat(node.values["cx"] ?? 0)
            let cy = CGFloat(node.values["cy"] ?? 0)
            let rx = CGFloat(node.values["rx"] ?? 0)
            let ry = CGFloat(node.values["ry"] ?? 0)
            path.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))

        case .line:
            let x1 = CGFloat(node.values["x1"] ?? 0)
            let y1 = CGFloat(node.values["y1"] ?? 0)
            let x2 = CGFloat(node.values["x2"] ?? 0)
            let y2 = CGFloat(node.values["y2"] ?? 0)
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))

        case .polyline:
            guard let first = node.points.first else {
                break
            }
            path.move(to: CGPoint(x: first.x, y: first.y))
            for point in node.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }

        case .polygon:
            guard let first = node.points.first else {
                break
            }
            path.move(to: CGPoint(x: first.x, y: first.y))
            for point in node.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            path.closeSubpath()

        case .path, .group, .svg:
            break
        }
        return path
    }
}
