import CoreGraphics

struct SVGTransformBuilder: Sendable {
    init() {}

    func makeCGAffineTransform(from transform: SVGTransform) -> CGAffineTransform {
        var result: CGAffineTransform = .identity
        for operation in transform.operations {
            let operationTransform: CGAffineTransform = makeOperationTransform(operation)
            result = result.concatenating(operationTransform)
        }
        return result
    }

    func concatenate(local: SVGTransform, inherited: CGAffineTransform) -> CGAffineTransform {
        let localTransform: CGAffineTransform = makeCGAffineTransform(from: local)
        return localTransform.concatenating(inherited)
    }

    private func makeOperationTransform(_ operation: SVGTransform.Operation) -> CGAffineTransform {
        switch operation {
        case .matrix(let a, let b, let c, let d, let tx, let ty):
            return CGAffineTransform(
                a: CGFloat(a),
                b: CGFloat(b),
                c: CGFloat(c),
                d: CGFloat(d),
                tx: CGFloat(tx),
                ty: CGFloat(ty)
            )
        case .translate(let tx, let ty):
            return CGAffineTransform(
                translationX: CGFloat(tx),
                y: CGFloat(ty)
            )
        case .scale(let sx, let sy):
            return CGAffineTransform(
                scaleX: CGFloat(sx),
                y: CGFloat(sy)
            )
        case .rotate(let angleDegrees, let cx, let cy):
            return makeRotateTransform(
                angleDegrees: angleDegrees,
                cx: cx,
                cy: cy
            )
        case .skewX(let angleDegrees):
            let angleRadians: Double = angleDegrees * (.pi / 180.0)
            let tanRadians: Double = tan(angleRadians)
            return CGAffineTransform(a: 1, b: 0, c: CGFloat(tanRadians), d: 1, tx: 0, ty: 0)
        case .skewY(let angleDegrees):
            let angleRadians: Double = angleDegrees * (.pi / 180.0)
            let tanRadians: Double = tan(angleRadians)
            return CGAffineTransform(a: 1, b: CGFloat(tanRadians), c: 0, d: 1, tx: 0, ty: 0)
        }
    }

    private func makeRotateTransform(
        angleDegrees: Double,
        cx: Double?,
        cy: Double?
    ) -> CGAffineTransform {
        let angleRadians: Double = angleDegrees * (.pi / 180.0)
        let rotation: CGAffineTransform = CGAffineTransform(rotationAngle: CGFloat(angleRadians))
        guard let cx, let cy else {
            return rotation
        }

        var centered: CGAffineTransform = .identity
        centered = centered.translatedBy(x: CGFloat(cx), y: CGFloat(cy))
        centered = centered.rotated(by: CGFloat(angleRadians))
        centered = centered.translatedBy(x: CGFloat(-cx), y: CGFloat(-cy))
        return centered
    }
}
