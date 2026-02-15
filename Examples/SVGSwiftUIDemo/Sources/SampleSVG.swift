import Foundation

enum DemoAnimation: Equatable {
    case none
    case pulse(nodeID: String, minScale: Double, maxScale: Double, duration: Double)
    case drift(nodeID: String, offsetX: Double, offsetY: Double, duration: Double)
    case opacity(nodeID: String, minOpacity: Double, maxOpacity: Double, duration: Double)

    var isAnimated: Bool {
        switch self {
        case .none:
            return false
        case .pulse, .drift, .opacity:
            return true
        }
    }
}

struct SampleSVG: Identifiable {
    let id: String
    let title: String
    let fileName: String
    let defaultNodeID: String
    let category: String
    let notes: String
    let animation: DemoAnimation
}

enum DemoSamples {
    static let all: [SampleSVG] = [
        SampleSVG(
            id: "badge",
            title: "Badge",
            fileName: "badge",
            defaultNodeID: "main-path",
            category: "Shapes",
            notes: "기본 원형+path로 된 아이콘 형태 샘플",
            animation: .none
        ),
        SampleSVG(
            id: "panel",
            title: "Panel",
            fileName: "panel",
            defaultNodeID: "panel-base",
            category: "Shapes",
            notes: "rect + line + circle 조합으로 레이아웃 구성",
            animation: .none
        ),
        SampleSVG(
            id: "route",
            title: "Route",
            fileName: "route",
            defaultNodeID: "route-line",
            category: "Path",
            notes: "polyline/polygon로 경로와 방향성을 확인",
            animation: .none
        ),
        SampleSVG(
            id: "geometry",
            title: "Geometry",
            fileName: "geometry",
            defaultNodeID: "geo-rect",
            category: "Geometry",
            notes: "gradient, rect/circle/ellipse/line의 렌더 우선순위 확인",
            animation: .none
        ),
        SampleSVG(
            id: "path-commands",
            title: "Path Commands",
            fileName: "path-commands",
            defaultNodeID: "cmd-bezier",
            category: "Path",
            notes: "M/L/C/S/A 등 주요 path 명령 분해 렌더 확인",
            animation: .none
        ),
        SampleSVG(
            id: "polygon-polyline",
            title: "Polygon/Polyline",
            fileName: "polygon-polyline",
            defaultNodeID: "poly-group",
            category: "Shapes",
            notes: "폴리곤/폴리라인 그룹 내 렌더링 정합성",
            animation: .none
        ),
        SampleSVG(
            id: "style-inline",
            title: "Inline Style",
            fileName: "style-inline",
            defaultNodeID: "styled-group",
            category: "Style",
            notes: "inline style attribute 파서/전파 동작 확인",
            animation: .none
        ),
        SampleSVG(
            id: "nested-groups",
            title: "Nested Group",
            fileName: "nested-groups",
            defaultNodeID: "inner-layer-1",
            category: "Transform",
            notes: "중첩 transform/opacity가 있는 그룹 계층 렌더 확인",
            animation: .none
        ),
        SampleSVG(
            id: "style-sheet",
            title: "Style Sheet",
            fileName: "style-sheet",
            defaultNodeID: "sheet-circle",
            category: "Style",
            notes: "style 태그의 class/id selector 동작을 위한 샘플",
            animation: .none
        ),
        SampleSVG(
            id: "animation-pulse",
            title: "Animated Pulse",
            fileName: "animation-pulse",
            defaultNodeID: "pulse-core",
            category: "Animation",
            notes: "SwiftUI 기반 타임라인으로 노드 scale 변화를 보이는 예제",
            animation: .pulse(nodeID: "pulse-core", minScale: 0.8, maxScale: 1.3, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-drift",
            title: "Animated Drift",
            fileName: "animation-drift",
            defaultNodeID: "drift-dot",
            category: "Animation",
            notes: "offset override로 노드의 좌우 이동을 확인",
            animation: .drift(nodeID: "drift-dot", offsetX: 70, offsetY: 0, duration: 2.2)
        ),
        SampleSVG(
            id: "mesh-network",
            title: "Mesh Network",
            fileName: "mesh-network",
            defaultNodeID: "mesh-node-3-4",
            category: "Complex",
            notes: "많은 노드와 에지 연결로 구성된 복잡한 네트워크형 구조",
            animation: .none
        ),
        SampleSVG(
            id: "spiral-paths",
            title: "Spiral Paths",
            fileName: "spiral-paths",
            defaultNodeID: "path-spiral-main",
            category: "Path",
            notes: "복합 곡선/원호 경로와 다중 path 조합",
            animation: .none
        ),
        SampleSVG(
            id: "orbital-lattice",
            title: "Orbital Lattice",
            fileName: "orbital-lattice",
            defaultNodeID: "lattice-center",
            category: "Transform",
            notes: "중첩 회전/동심원 그룹으로 구성된 구조 복잡도 높은 예시",
            animation: .none
        ),
        SampleSVG(
            id: "animation-luminous-core",
            title: "Animated Luminous Core",
            fileName: "animation-luminous-core",
            defaultNodeID: "luminous-core",
            category: "Animation",
            notes: "다수의 노드 + 핵심 코어 스케일 애니메이션",
            animation: .pulse(nodeID: "luminous-core", minScale: 0.85, maxScale: 1.25, duration: 1.8)
        ),
        SampleSVG(
            id: "aurora-wave",
            title: "Aurora Wave",
            fileName: "aurora-wave",
            defaultNodeID: "aurora-core",
            category: "Filter",
            notes: "clipPath + filter(blur/colormatrix)를 포함한 화려한 파형 구성",
            animation: .none
        ),
        SampleSVG(
            id: "dense-grid-world",
            title: "Dense Grid World",
            fileName: "dense-grid-world",
            defaultNodeID: "grid-node-4-7",
            category: "Complex",
            notes: "노드 100개 이상을 가진 다단계 그리드 + 다중 링크 네트워크",
            animation: .none
        ),
        SampleSVG(
            id: "polyline-ribbon",
            title: "Polyline Ribbon",
            fileName: "polyline-ribbon",
            defaultNodeID: "ribbon-poly-12",
            category: "Path",
            notes: "다수의 polyline/폴리곤으로 만든 긴 스트립 구조",
            animation: .none
        ),
        SampleSVG(
            id: "constellation-grid",
            title: "Constellation Grid",
            fileName: "constellation-grid",
            defaultNodeID: "star-00-00",
            category: "Complex",
            notes: "수백 개의 circle/line을 가진 노드 밀집형 네트워크형 조합",
            animation: .none
        ),
        SampleSVG(
            id: "transform-radial-spiral",
            title: "Transform Spiral",
            fileName: "transform-radial-spiral",
            defaultNodeID: "blade-spine-0",
            category: "Transform",
            notes: "다중 회전/스케일 조합의 복합 transform + filter 적용",
            animation: .none
        )
    ]

    @MainActor
    private static var sourceCache: [String: String] = [:]

    @MainActor
    static func source(for sample: SampleSVG) -> String {
        if let cached = sourceCache[sample.id] {
            return cached
        }

        let loadedSource = DemoSamples.loadSource(fileName: sample.fileName)
        sourceCache[sample.id] = loadedSource
        return loadedSource
    }

    private static func loadSource(fileName: String) -> String {
        let baseName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let candidateNames = [baseName, fileName]
        for candidate in candidateNames {
            if let url = Bundle.main.url(forResource: candidate, withExtension: "svg"),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                return source
            }

            if let url = Bundle.main.url(forResource: candidate, withExtension: nil),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                return source
            }
        }

        if let resourcePath = Bundle.main.resourcePath {
            let directPath = "\(resourcePath)/\(baseName).svg"
            if let source = try? String(contentsOfFile: directPath, encoding: .utf8) {
                return source
            }

            let resourcesDirectoryPath = "\(resourcePath)/Resources/\(baseName).svg"
            if let source = try? String(contentsOfFile: resourcesDirectoryPath, encoding: .utf8) {
                return source
            }

            let fallbackPath = "\(resourcePath)/Resources/\(fileName).svg"
            if let source = try? String(contentsOfFile: fallbackPath, encoding: .utf8) {
                return source
            }
        }

        let missingResourceName = "\(baseName).svg"
        return "<!-- Unable to load demo sample: \(missingResourceName) -->"
    }
}
