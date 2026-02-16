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
    let sourceFilePath: String?
    let defaultNodeID: String
    let overrideTargets: [String]
    let category: String
    let notes: String
    let animation: DemoAnimation

    init(
        id: String,
        title: String,
        fileName: String,
        sourceFilePath: String? = nil,
        defaultNodeID: String,
        overrideTargets: [String],
        category: String,
        notes: String,
        animation: DemoAnimation
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.sourceFilePath = sourceFilePath
        self.defaultNodeID = defaultNodeID
        self.overrideTargets = overrideTargets
        self.category = category
        self.notes = notes
        self.animation = animation
    }
}

enum DemoSamples {
    private static let dimensionMatcher = try? NSRegularExpression(
        pattern: #"\b(?:width|height)\s*=\s*["']([0-9]+(?:\.[0-9]+)?)"#
    )
    private static let legacyW3CCaseIDs: Set<String> = [
        "mesh-network",
        "spiral-paths",
        "style-sheet",
        "orbital-lattice",
        "aurora-wave",
        "dense-grid-world"
    ]
    private static let w3cManifest = "W3C/w3c-manifest.json"
    private static let webKitManifest = "WebKit/webkit-manifest.json"
    private static let w3cFixturesRoot = "W3C"
    private static let webKitFixturesRoot = "WebKit"

    private struct DemoFixtureManifest: Decodable {
        let fixtures: [DemoFixtureEntry]
    }

    private struct DemoFixtureEntry: Decodable {
        let id: String
        let svg: String
        let suite: String?
        let category: String?
    }

    static let w3cFixtureSamples: [SampleSVG] = {
        loadFixtureSamples(
            manifestPath: w3cManifest,
            sourceRootPath: w3cFixturesRoot,
            defaultCategory: "W3C"
        )
    }()

    static let webKitFixtureSamples: [SampleSVG] = {
        loadFixtureSamples(
            manifestPath: webKitManifest,
            sourceRootPath: webKitFixturesRoot,
            defaultCategory: "WebKit"
        )
    }()

    static let w3cCatalogSamples: [SampleSVG] = {
        let curated = all.filter { legacyW3CCaseIDs.contains($0.id) }
        return uniqueSamples(from: curated + w3cFixtureSamples + webKitFixtureSamples)
    }()

    static let smilSamples: [SampleSVG] = {
        let filtered = all.filter { $0.id.hasPrefix("animation-smil-") }
        return filtered
    }()

    static let w3cCatalogCaseIDs: Set<String> = Set(w3cCatalogSamples.map(\.id))

    static let all: [SampleSVG] = [
        SampleSVG(
            id: "badge",
            title: "Badge",
            fileName: "badge",
            defaultNodeID: "main-path",
            overrideTargets: ["badge-group", "main-path"],
            category: "Shapes",
            notes: "기본 원형+path로 된 아이콘 형태 샘플",
            animation: .none
        ),
        SampleSVG(
            id: "panel",
            title: "Panel",
            fileName: "panel",
            defaultNodeID: "panel-base",
            overrideTargets: ["panel-base", "panel-divider", "panel-dot"],
            category: "Shapes",
            notes: "rect + line + circle 조합으로 레이아웃 구성",
            animation: .none
        ),
        SampleSVG(
            id: "route",
            title: "Route",
            fileName: "route",
            defaultNodeID: "route-line",
            overrideTargets: ["route-line", "route-arrow"],
            category: "Path",
            notes: "polyline/polygon로 경로와 방향성을 확인",
            animation: .none
        ),
        SampleSVG(
            id: "geometry",
            title: "Geometry",
            fileName: "geometry",
            defaultNodeID: "geo-rect",
            overrideTargets: ["geo-rect", "geo-circle", "geo-ellipse", "geo-line"],
            category: "Geometry",
            notes: "gradient, rect/circle/ellipse/line의 렌더 우선순위 확인",
            animation: .none
        ),
        SampleSVG(
            id: "path-commands",
            title: "Path Commands",
            fileName: "path-commands",
            defaultNodeID: "cmd-bezier",
            overrideTargets: ["cmd-move-line", "cmd-bezier", "cmd-arc", "cmd-close"],
            category: "Path",
            notes: "M/L/C/S/A 등 주요 path 명령 분해 렌더 확인",
            animation: .none
        ),
        SampleSVG(
            id: "polygon-polyline",
            title: "Polygon/Polyline",
            fileName: "polygon-polyline",
            defaultNodeID: "poly-group",
            overrideTargets: ["poly-group", "poly-star", "polyline-wave", "poly-triangle"],
            category: "Shapes",
            notes: "폴리곤/폴리라인 그룹 내 렌더링 정합성",
            animation: .none
        ),
        SampleSVG(
            id: "style-inline",
            title: "Inline Style",
            fileName: "style-inline",
            defaultNodeID: "styled-group",
            overrideTargets: ["styled-group", "styled-bg", "styled-card", "styled-dot", "styled-text"],
            category: "Style",
            notes: "inline style attribute 파서/전파 동작 확인",
            animation: .none
        ),
        SampleSVG(
            id: "nested-groups",
            title: "Nested Group",
            fileName: "nested-groups",
            defaultNodeID: "inner-layer-1",
            overrideTargets: ["root-group", "inner-layer-1", "inner-layer-2", "nested-a", "nested-b"],
            category: "Transform",
            notes: "중첩 transform/opacity가 있는 그룹 계층 렌더 확인",
            animation: .none
        ),
        SampleSVG(
            id: "style-sheet",
            title: "Style Sheet",
            fileName: "style-sheet",
            defaultNodeID: "sheet-circle",
            overrideTargets: ["sheet-circle", "text"],
            category: "Style",
            notes: "style 태그의 class/id selector 동작을 위한 샘플",
            animation: .none
        ),
        SampleSVG(
            id: "animation-pulse",
            title: "Animated Pulse",
            fileName: "animation-pulse",
            defaultNodeID: "pulse-core",
            overrideTargets: ["pulse-core", "pulse-bg", "pulse-text"],
            category: "Animation",
            notes: "SwiftUI 기반 타임라인으로 노드 scale 변화를 보이는 예제",
            animation: .pulse(nodeID: "pulse-core", minScale: 0.8, maxScale: 1.3, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-drift",
            title: "Animated Drift",
            fileName: "animation-drift",
            defaultNodeID: "drift-dot",
            overrideTargets: ["drift-dot", "drift-track"],
            category: "Animation",
            notes: "offset override로 노드의 좌우 이동을 확인",
            animation: .drift(nodeID: "drift-dot", offsetX: 70, offsetY: 0, duration: 2.2)
        ),
        SampleSVG(
            id: "mesh-network",
            title: "Mesh Network",
            fileName: "mesh-network",
            defaultNodeID: "mesh-node-3-4",
            overrideTargets: ["mesh-bg", "mesh-grid", "mesh-node-2-2", "mesh-node-3-4"],
            category: "Complex",
            notes: "많은 노드와 에지 연결로 구성된 복잡한 네트워크형 구조",
            animation: .none
        ),
        SampleSVG(
            id: "spiral-paths",
            title: "Spiral Paths",
            fileName: "spiral-paths",
            defaultNodeID: "path-spiral-main",
            overrideTargets: ["path-spiral-main", "path-spiral-shadow", "spiral-nodes", "path-bg"],
            category: "Path",
            notes: "복합 곡선/원호 경로와 다중 path 조합",
            animation: .none
        ),
        SampleSVG(
            id: "orbital-lattice",
            title: "Orbital Lattice",
            fileName: "orbital-lattice",
            defaultNodeID: "lattice-center",
            overrideTargets: ["lattice-center", "orbital-core", "orbital-ring-0", "orbital-shell-0"],
            category: "Transform",
            notes: "중첩 회전/동심원 그룹으로 구성된 구조 복잡도 높은 예시",
            animation: .none
        ),
        SampleSVG(
            id: "animation-luminous-core",
            title: "Animated Luminous Core",
            fileName: "animation-luminous-core",
            defaultNodeID: "luminous-core",
            overrideTargets: ["luminous-core", "luminous-bg", "luminous-stage", "luminous-ring-1", "luminous-ring-2", "luminous-ring-3"],
            category: "Animation",
            notes: "다수의 노드 + 핵심 코어 스케일 애니메이션",
            animation: .pulse(nodeID: "luminous-core", minScale: 0.85, maxScale: 1.25, duration: 1.8)
        ),
        SampleSVG(
            id: "animation-opacity-pulse",
            title: "Animated Opacity",
            fileName: "path-commands",
            defaultNodeID: "cmd-close",
            overrideTargets: ["cmd-close", "cmd-move-line", "cmd-bezier", "cmd-arc"],
            category: "Animation",
            notes: "투명도 페이드 인/아웃을 통해 opacity 애니메이션 동작을 확인",
            animation: .opacity(nodeID: "cmd-close", minOpacity: 0.15, maxOpacity: 1.0, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-badge-breath",
            title: "Animated Badge Breath",
            fileName: "badge",
            defaultNodeID: "badge-group",
            overrideTargets: ["badge-group", "badge-ring", "main-path"],
            category: "Animation",
            notes: "아이콘 핵심 루프의 scale 변화를 확인",
            animation: .pulse(nodeID: "badge-group", minScale: 0.88, maxScale: 1.24, duration: 1.8)
        ),
        SampleSVG(
            id: "animation-route-flow",
            title: "Animated Route Flow",
            fileName: "route",
            defaultNodeID: "route-line",
            overrideTargets: ["route-line", "route-arrow"],
            category: "Animation",
            notes: "경로 노드의 offset 이동을 통해 drift 동작을 확인",
            animation: .drift(nodeID: "route-line", offsetX: 38, offsetY: 0, duration: 2.4)
        ),
        SampleSVG(
            id: "animation-geometry-fade",
            title: "Animated Geometry Fade",
            fileName: "geometry",
            defaultNodeID: "geo-circle",
            overrideTargets: ["geo-circle", "geo-rect", "geo-ellipse", "geo-line"],
            category: "Animation",
            notes: "원형 노드의 투명도 변화를 통해 alpha 애니메이션 확인",
            animation: .opacity(nodeID: "geo-circle", minOpacity: 0.25, maxOpacity: 1.0, duration: 1.8)
        ),
        SampleSVG(
            id: "animation-panel-bounce",
            title: "Animated Panel Dot",
            fileName: "panel",
            defaultNodeID: "panel-dot",
            overrideTargets: ["panel-dot", "panel-divider", "panel-base"],
            category: "Animation",
            notes: "패널 내 포인트의 scale 변화를 통해 펄스 동작 확인",
            animation: .pulse(nodeID: "panel-dot", minScale: 0.65, maxScale: 1.35, duration: 2.1)
        ),
        SampleSVG(
            id: "animation-style-sheet-fade",
            title: "Animated Style Sheet Fade",
            fileName: "style-sheet",
            defaultNodeID: "sheet-circle",
            overrideTargets: ["sheet-circle", "text"],
            category: "Animation",
            notes: "스타일 시트 샘플에서 stroke/fill 요소를 타겟한 opacity 동작",
            animation: .opacity(nodeID: "sheet-circle", minOpacity: 0.2, maxOpacity: 1.0, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-polygon-pulse",
            title: "Animated Polygon Pulse",
            fileName: "polygon-polyline",
            defaultNodeID: "poly-star",
            overrideTargets: ["poly-star", "poly-group", "polyline-wave", "poly-triangle"],
            category: "Animation",
            notes: "폴리곤 노드의 scale 변화를 통한 간단한 애니메이션 동작 확인",
            animation: .pulse(nodeID: "poly-star", minScale: 0.8, maxScale: 1.22, duration: 1.7)
        ),
        SampleSVG(
            id: "animation-aurora-wisp",
            title: "Animated Aurora Wisp",
            fileName: "aurora-wave",
            defaultNodeID: "aurora-vision",
            overrideTargets: ["aurora-vision", "aurora-glow", "aurora-backdrop", "aurora-ribbon-1"],
            category: "Animation",
            notes: "필터 기반 복합 도형에서 노드 투명도 변화를 확인",
            animation: .opacity(nodeID: "aurora-glow", minOpacity: 0.2, maxOpacity: 1.0, duration: 2.2)
        ),
        SampleSVG(
            id: "animation-nested-drift",
            title: "Animated Nested Drift",
            fileName: "nested-groups",
            defaultNodeID: "inner-layer-1",
            overrideTargets: ["inner-layer-1", "inner-layer-2", "nested-a", "nested-b", "root-group"],
            category: "Animation",
            notes: "중첩 그룹의 레이어를 offset 변경해 drift 동작 확인",
            animation: .drift(nodeID: "inner-layer-1", offsetX: 16, offsetY: 10, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-transform-radiant",
            title: "Animated Transform Core",
            fileName: "transform-radial-spiral",
            defaultNodeID: "spiral-core",
            overrideTargets: ["spiral-core", "spiral-body", "spiral-core-shell", "spiral-glow", "spiral-bg"],
            category: "Animation",
            notes: "중첩 transform 구조에서 핵심 코어 scale 동작을 확인",
            animation: .pulse(nodeID: "spiral-core", minScale: 0.9, maxScale: 1.18, duration: 2.3)
        ),
        SampleSVG(
            id: "animation-smil-orbital",
            title: "SMIL Orbital",
            fileName: "animation-smil-orbital",
            sourceFilePath: "W3C/animation/animation-smil-orbital.svg",
            defaultNodeID: "smil-orbit-core",
            overrideTargets: [
                "smil-orbit-core",
                "smil-orbit-ring",
                "smil-orbit-halo",
                "smil-orbit-satellite",
                "smil-orbit-shell"
            ],
            category: "Animation",
            notes: "SMIL animateTransform 예제가 포함된 궤도형 샘플입니다.",
            animation: .pulse(nodeID: "smil-orbit-core", minScale: 0.86, maxScale: 1.22, duration: 1.9)
        ),
        SampleSVG(
            id: "animation-smil-orbit-lumen",
            title: "SMIL Orbit Lumen",
            fileName: "animation-smil-orbit-lumen",
            sourceFilePath: "W3C/animation/animation-smil-orbit-lumen.svg",
            defaultNodeID: "smil-orbit-lumen-core",
            overrideTargets: [
                "smil-orbit-lumen-core",
                "smil-orbit-lumen-core-group",
                "smil-orbit-lumen-core-ring",
                "smil-orbit-lumen-orbit",
                "smil-orbit-lumen-satellite-0",
                "smil-orbit-lumen-satellite-3",
                "smil-orbit-lumen-satellite-5"
            ],
            category: "Animation",
            notes: "궤도 회전에 코어 스케일 애니메이션을 추가한 SMIL 샘플입니다.",
            animation: .pulse(nodeID: "smil-orbit-lumen-core", minScale: 0.86, maxScale: 1.24, duration: 2.4)
        ),
        SampleSVG(
            id: "animation-smil-drift-lines",
            title: "SMIL Drift Lines",
            fileName: "animation-smil-drift-lines",
            sourceFilePath: "W3C/animation/animation-smil-drift-lines.svg",
            defaultNodeID: "smil-drift-ball",
            overrideTargets: [
                "smil-drift-ball",
                "smil-drift-track",
                "smil-drift-line-1",
                "smil-drift-line-2",
                "smil-drift-line-3"
            ],
            category: "Animation",
            notes: "SMIL animate 포함 드리프트 형상 샘플입니다.",
            animation: .drift(nodeID: "smil-drift-ball", offsetX: 72, offsetY: 0, duration: 2.8)
        ),
        SampleSVG(
            id: "animation-smil-breath-grid",
            title: "SMIL Breath Grid",
            fileName: "animation-smil-breath-grid",
            sourceFilePath: "W3C/animation/animation-smil-breath-grid.svg",
            defaultNodeID: "smil-breath-grid-frame",
            overrideTargets: [
                "smil-breath-grid-frame",
                "smil-breath-grid-row-0",
                "smil-breath-grid-row-1",
                "smil-breath-grid-row-2",
                "smil-breath-grid-row-3",
                "smil-breath-breath-panel",
                "smil-breath-breath-core"
            ],
            category: "Animation",
            notes: "행 단위로 이동 transform과 width 애니메이션을 포함한 SMIL 샘플입니다.",
            animation: .drift(nodeID: "smil-breath-grid-row-0", offsetX: 6, offsetY: 2, duration: 2.4)
        ),
        SampleSVG(
            id: "animation-smil-opacity-breath",
            title: "SMIL Opacity Breath",
            fileName: "animation-smil-opacity-breath",
            sourceFilePath: "W3C/animation/animation-smil-opacity-breath.svg",
            defaultNodeID: "smil-breath-core",
            overrideTargets: [
                "smil-breath-core",
                "smil-breath-haze",
                "smil-breath-rim",
                "smil-breath-beam"
            ],
            category: "Animation",
            notes: "SMIL opacity/색상 애니메이션 샘플입니다.",
            animation: .opacity(nodeID: "smil-breath-haze", minOpacity: 0.2, maxOpacity: 1.0, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-smil-radar-spin",
            title: "SMIL Radar Sweep",
            fileName: "animation-smil-radar-spin",
            sourceFilePath: "W3C/animation/animation-smil-radar-spin.svg",
            defaultNodeID: "smil-radar-core",
            overrideTargets: [
                "smil-radar-core",
                "smil-radar-sweep",
                "smil-radar-dot-a",
                "smil-radar-dot-b",
                "smil-radar-dot-c"
            ],
            category: "Animation",
            notes: "SMIL animateTransform 방식의 레이더형 샘플입니다.",
            animation: .pulse(nodeID: "smil-radar-core", minScale: 0.84, maxScale: 1.2, duration: 1.8)
        ),
        SampleSVG(
            id: "animation-smil-mosaic-grid",
            title: "SMIL Mosaic Grid",
            fileName: "animation-smil-mosaic-grid",
            sourceFilePath: "W3C/animation/animation-smil-mosaic-grid.svg",
            defaultNodeID: "smil-mosaic-center",
            overrideTargets: [
                "smil-mosaic-center",
                "smil-mosaic-a",
                "smil-mosaic-b",
                "smil-mosaic-c",
                "smil-mosaic-d",
                "smil-mosaic-e"
            ],
            category: "Animation",
            notes: "스타일/클래스가 섞인 격자형 SMIL 샘플입니다.",
            animation: .pulse(nodeID: "smil-mosaic-center", minScale: 0.9, maxScale: 1.3, duration: 2.2)
        ),
        SampleSVG(
            id: "animation-smil-path-signal",
            title: "SMIL Path Signal",
            fileName: "animation-smil-path-signal",
            sourceFilePath: "W3C/animation/animation-smil-path-signal.svg",
            defaultNodeID: "smil-path-marker",
            overrideTargets: [
                "smil-path-marker",
                "smil-path-track",
                "smil-path-node-a",
                "smil-path-node-b",
                "smil-path-node-c"
            ],
            category: "Animation",
            notes: "SMIL motion 요소 샘플(구조 점검용)입니다.",
            animation: .drift(nodeID: "smil-path-marker", offsetX: 10, offsetY: 6, duration: 1.9)
        ),
        SampleSVG(
            id: "animation-smil-pulse-sunburst",
            title: "SMIL Pulse Sunburst",
            fileName: "animation-smil-pulse-sunburst",
            sourceFilePath: "W3C/animation/animation-smil-pulse-sunburst.svg",
            defaultNodeID: "smil-pulse-sun-core",
            overrideTargets: [
                "smil-pulse-sun-core",
                "smil-pulse-sun-ring-1",
                "smil-pulse-sun-ring-2",
                "smil-pulse-ray",
                "smil-pulse-ray-2",
                "smil-pulse-ray-3",
                "smil-pulse-ray-4",
                "smil-pulse-ray-5",
                "smil-pulse-ray-6"
            ],
            category: "Animation",
            notes: "SMIL으로 반경이 확장되는 태양형 애니메이션을 포함한 샘플입니다.",
            animation: .pulse(nodeID: "smil-pulse-sun-core", minScale: 0.9, maxScale: 1.3, duration: 2.6)
        ),
        SampleSVG(
            id: "animation-smil-spin-petal",
            title: "SMIL Spinning Petal",
            fileName: "animation-smil-spin-petal",
            sourceFilePath: "W3C/animation/animation-smil-spin-petal.svg",
            defaultNodeID: "smil-petal-wheel",
            overrideTargets: [
                "smil-petal-center",
                "smil-petal-wheel",
                "smil-petal-arm-group",
                "smil-petal-arm-1",
                "smil-petal-arm-2",
                "smil-petal-arm-3",
                "smil-petal-arm-4"
            ],
            category: "Animation",
            notes: "반복 회전 transform을 포함한 SMIL 샘플입니다.",
            animation: .pulse(nodeID: "smil-petal-wheel", minScale: 0.9, maxScale: 1.15, duration: 2.0)
        ),
        SampleSVG(
            id: "animation-smil-color-lattice",
            title: "SMIL Color Lattice",
            fileName: "animation-smil-color-lattice",
            sourceFilePath: "W3C/animation/animation-smil-color-lattice.svg",
            defaultNodeID: "smil-lattice-square-1",
            overrideTargets: [
                "smil-lattice-bg",
                "smil-lattice-square-1",
                "smil-lattice-square-2",
                "smil-lattice-square-3",
                "smil-lattice-square-4",
                "smil-lattice-square-5",
                "smil-lattice-square-6",
                "smil-lattice-square-7",
                "smil-lattice-square-8"
            ],
            category: "Animation",
            notes: "그리드 상자 구성이 포함된 SMIL 샘플입니다.",
            animation: .drift(nodeID: "smil-lattice-bg", offsetX: 4, offsetY: 1, duration: 2.2)
        ),
        SampleSVG(
            id: "animation-smil-pendulum-sweep",
            title: "SMIL Pendulum Sweep",
            fileName: "animation-smil-pendulum-sweep",
            sourceFilePath: "W3C/animation/animation-smil-pendulum-sweep.svg",
            defaultNodeID: "smil-pendulum-bob-group",
            overrideTargets: [
                "smil-pendulum-bob",
                "smil-pendulum-bob-group",
                "smil-pendulum-glow",
                "smil-pendulum-rod",
                "smil-pendulum-pivot"
            ],
            category: "Animation",
            notes: "중심에서 왕복 회전하는 진자형 SMIL 샘플입니다.",
            animation: .drift(nodeID: "smil-pendulum-bob-group", offsetX: 28, offsetY: 4, duration: 2.2)
        ),
        SampleSVG(
            id: "animation-smil-wave-cascade",
            title: "SMIL Wave Cascade",
            fileName: "animation-smil-wave-cascade",
            sourceFilePath: "W3C/animation/animation-smil-wave-cascade.svg",
            defaultNodeID: "smil-wave-bubble-1",
            overrideTargets: [
                "smil-wave-path",
                "smil-wave-bubble-1",
                "smil-wave-bubble-2",
                "smil-wave-bubble-3",
                "smil-wave-gridline-1",
                "smil-wave-gridline-2",
                "smil-wave-bg"
            ],
            category: "Animation",
            notes: "연속 이동형 SMIL 예시로 동작 점검이 쉬운 샘플입니다.",
            animation: .drift(nodeID: "smil-wave-bubble-1", offsetX: 24, offsetY: 0, duration: 3.6)
        ),
        SampleSVG(
            id: "animation-smil-wave-shimmer",
            title: "SMIL Wave Shimmer",
            fileName: "animation-smil-wave-shimmer",
            sourceFilePath: "W3C/animation/animation-smil-wave-shimmer.svg",
            defaultNodeID: "smil-wave-shimmer-band",
            overrideTargets: [
                "smil-wave-shimmer-band",
                "smil-wave-shimmer-halo",
                "smil-wave-shimmer-core-dot",
                "smil-wave-shimmer-light-0",
                "smil-wave-shimmer-light-1",
                "smil-wave-shimmer-light-2",
                "smil-wave-shimmer-light-3"
            ],
            category: "Animation",
            notes: "파동형 path 애니메이션과 빛 스캐닝 rect 모션을 가진 SMIL 샘플입니다.",
            animation: .pulse(nodeID: "smil-wave-shimmer-band", minScale: 0.94, maxScale: 1.08, duration: 2.1)
        ),
        SampleSVG(
            id: "animation-smil-orbit-multi-ring",
            title: "SMIL Multi Ring Orbit",
            fileName: "animation-smil-orbit-multi-ring",
            sourceFilePath: "W3C/animation/animation-smil-orbit-multi-ring.svg",
            defaultNodeID: "smil-orbit-multi-core",
            overrideTargets: [
                "smil-orbit-multi-core",
                "smil-orbit-multi-ring-a",
                "smil-orbit-multi-ring-b",
                "smil-orbit-multi-ring-a-1",
                "smil-orbit-multi-ring-b-1",
                "smil-orbit-multi-bg"
            ],
            category: "Animation",
            notes: "이중 회전 고리 구성이 포함된 SMIL 샘플입니다.",
            animation: .pulse(nodeID: "smil-orbit-multi-core", minScale: 0.88, maxScale: 1.12, duration: 2.8)
        ),
        SampleSVG(
            id: "aurora-wave",
            title: "Aurora Wave",
            fileName: "aurora-wave",
            defaultNodeID: "aurora-core",
            overrideTargets: ["aurora-vision", "aurora-glow", "aurora-backdrop", "aurora-ribbon-1", "aurora-clip"],
            category: "Filter",
            notes: "clipPath + filter(blur/colormatrix)를 포함한 화려한 파형 구성",
            animation: .none
        ),
        SampleSVG(
            id: "dense-grid-world",
            title: "Dense Grid World",
            fileName: "dense-grid-world",
            defaultNodeID: "grid-node-4-7",
            overrideTargets: ["grid-bg", "grid-stage", "grid-halo", "grid-node-4-7"],
            category: "Complex",
            notes: "노드 100개 이상을 가진 다단계 그리드 + 다중 링크 네트워크",
            animation: .none
        ),
        SampleSVG(
            id: "polyline-ribbon",
            title: "Polyline Ribbon",
            fileName: "polyline-ribbon",
            defaultNodeID: "ribbon-poly-12",
            overrideTargets: ["ribbon-bg", "ribbon-grid", "ribbon-poly-0", "ribbon-poly-0-mirror", "ribbon-poly-12"],
            category: "Path",
            notes: "다수의 polyline/폴리곤으로 만든 긴 스트립 구조",
            animation: .none
        ),
        SampleSVG(
            id: "constellation-grid",
            title: "Constellation Grid",
            fileName: "constellation-grid",
            defaultNodeID: "star-00-00",
            overrideTargets: ["constellation-root", "constellation-stars", "constellation-glow", "constellation-background", "star-00-00"],
            category: "Complex",
            notes: "수백 개의 circle/line을 가진 노드 밀집형 네트워크형 조합",
            animation: .none
        ),
        SampleSVG(
            id: "transform-radial-spiral",
            title: "Transform Spiral",
            fileName: "transform-radial-spiral",
            defaultNodeID: "spiral-core",
            overrideTargets: ["spiral-core", "spiral-glow", "spiral-bg", "spiral-body", "spiral-stage", "spiral-core-shell"],
            category: "Transform",
            notes: "다중 회전/스케일 조합의 복합 transform + filter 적용",
            animation: .none
        )
    ]

    @MainActor
    private static var sourceCache: [String: String] = [:]
    @MainActor
    private static var sourceDataCache: [String: Data] = [:]
    @MainActor
    private static var preferredCanvasSizeCache: [String: CGSize] = [:]

    @MainActor
    static func source(for sample: SampleSVG) -> String {
        if let cached = sourceCache[sample.id] {
            return cached
        }

        let loadedSource = DemoSamples.loadSource(for: sample)
        sourceCache[sample.id] = loadedSource
        return loadedSource
    }

    @MainActor
    static func sourceData(for sample: SampleSVG) -> Data {
        if let cached = sourceDataCache[sample.id] {
            return cached
        }

        let loadedData = DemoSamples.loadSourceData(for: sample)
        sourceDataCache[sample.id] = loadedData
        return loadedData
    }

    @MainActor
    static func preferredCanvasSize(for sample: SampleSVG) -> CGSize? {
        if let cached = preferredCanvasSizeCache[sample.id] {
            return cached
        }

        let source = DemoSamples.source(for: sample)
        let svgHeader = source
            .split(separator: "<", omittingEmptySubsequences: false)
            .first { segment in
                segment.lowercased().hasPrefix("svg")
            }
        guard let rawSVGHeader = svgHeader else {
            return nil
        }

        var width: CGFloat?
        var height: CGFloat?
        let headerText = "<\(rawSVGHeader)>"
        if let matcher = dimensionMatcher {
            let ranges = matcher.matches(
                in: headerText,
                options: [],
                range: NSRange(location: 0, length: headerText.utf16.count)
            )
            for rangeResult in ranges {
                let matchedRange = rangeResult.range(at: 0)
                let valueRange = rangeResult.range(at: 1)
                guard valueRange.location != NSNotFound,
                      let fullRange = Range(matchedRange, in: headerText),
                      let valueTextRange = Range(valueRange, in: headerText) else {
                    continue
                }
                let attributeText = String(headerText[fullRange]).lowercased()
                let value = Double(headerText[valueTextRange]) ?? 0
                if !value.isFinite || value <= 0 {
                    continue
                }
                if attributeText.contains("width") {
                    width = CGFloat(value)
                }
                if attributeText.contains("height") {
                    height = CGFloat(value)
                }
            }
        }

        guard let widthValue = width, let heightValue = height else {
            return nil
        }
        let resolvedSize = CGSize(width: widthValue, height: heightValue)
        preferredCanvasSizeCache[sample.id] = resolvedSize
        return resolvedSize
    }

    private static func loadSource(for sample: SampleSVG) -> String {
        let candidatePaths = candidateSourcePaths(for: sample)
        let resourceBundle = Bundle.main
        let missingResource = candidatePaths.first ?? sample.fileName

        if let source = sourceFromBundle(resourceBundle, filePaths: candidatePaths) {
            return source
        }

        if let resourcePath = Bundle.main.resourcePath,
           let source = sourceFromResourcePath(resourcePath, filePaths: candidatePaths) {
            return source
        }

        return missingResourceSource(for: "\(missingResource).svg")
    }

    private static func loadSourceData(for sample: SampleSVG) -> Data {
        let candidatePaths = candidateSourcePaths(for: sample)
        let resourceBundle = Bundle.main
        let missingResource = candidatePaths.first ?? sample.fileName

        if let data = sourceDataFromBundle(resourceBundle, filePaths: candidatePaths) {
            return data
        }

        if let resourcePath = Bundle.main.resourcePath,
           let data = sourceDataFromResourcePath(resourcePath, filePaths: candidatePaths) {
            return data
        }

        return missingResourceSource(for: "\(missingResource).svg").data(using: .utf8) ?? Data()
    }

    private static func candidateSourcePaths(for sample: SampleSVG) -> [String] {
        let explicitPath = normalizedResourcePath(
            sample.sourceFilePath ?? sample.fileName
        )
        return expandedResourcePaths(from: explicitPath)
    }

    private static func loadFixtureSamples(
        manifestPath: String,
        sourceRootPath: String,
        defaultCategory: String
    ) -> [SampleSVG] {
        let manifestFiles = sourceDataFromResourcePath(
            Bundle.main.resourcePath ?? "",
            filePaths: [manifestPath]
        )
        guard let manifestData = manifestFiles else {
            return []
        }
        do {
            let manifest = try JSONDecoder().decode(DemoFixtureManifest.self, from: manifestData)
            return manifest.fixtures.compactMap { fixture in
                let fixturePath = normalizedResourcePath(
                    "\(sourceRootPath)/\(fixture.svg)"
                )
                return SampleSVG(
                    id: fixture.id,
                    title: makeFixtureTitle(from: fixture.id),
                    fileName: fixture.svg,
                    sourceFilePath: fixturePath,
                    defaultNodeID: "",
                    overrideTargets: [],
                    category: fixture.category
                        ?? fixture.suite
                        ?? defaultCategory,
                    notes: "\(defaultCategory) fixture case",
                    animation: .none
                )
            }
        } catch {
            return []
        }
    }

    private static func uniqueSamples(from samples: [SampleSVG]) -> [SampleSVG] {
        var seen = Set<String>()
        var result: [SampleSVG] = []
        for sample in samples {
            if seen.insert(sample.id).inserted {
                result.append(sample)
            }
        }
        return result
    }

    private static func makeFixtureTitle(from id: String) -> String {
        return id
            .split(separator: "-")
            .map { part in
                String(part).capitalized
            }
            .joined(separator: " ")

    }

    private static func sourceFromBundle(
        _ bundle: Bundle,
        filePaths: [String]
    ) -> String? {
        for sourcePath in filePaths {
            let normalized = normalizedResourcePath(sourcePath)
            let name = URL(fileURLWithPath: normalized).deletingPathExtension().lastPathComponent
            let fileExtension = URL(fileURLWithPath: normalized).pathExtension
            let directory = URL(fileURLWithPath: normalized).deletingLastPathComponent().path
            let directoryPath = directory == "." || directory.isEmpty ? nil : directory

            var candidateNames: [String] = [normalized]
            if fileExtension.isEmpty {
                candidateNames.append(name)
            }

            for candidate in candidateNames {
                let normalizedCandidate = normalizedResourcePath(candidate)
                let candidateExtension = URL(fileURLWithPath: normalizedCandidate).pathExtension
                let candidateName = URL(fileURLWithPath: normalizedCandidate)
                    .deletingPathExtension().lastPathComponent
                let candidateDirectory = URL(fileURLWithPath: normalizedCandidate)
                    .deletingLastPathComponent().path
                let lookupDirectory = candidateDirectory == "." || candidateDirectory.isEmpty
                    ? directoryPath
                    : candidateDirectory

                if let url = bundle.url(
                    forResource: candidateName,
                    withExtension: candidateExtension.isEmpty ? "svg" : candidateExtension,
                    subdirectory: lookupDirectory
                ),
                let source = try? String(contentsOf: url, encoding: .utf8) {
                    return source
                }

                if let url = bundle.url(
                    forResource: candidateName,
                    withExtension: nil,
                    subdirectory: lookupDirectory
                ),
                let source = try? String(contentsOf: url, encoding: .utf8) {
                    return source
                }

                if let url = bundle.url(
                    forResource: normalizedCandidate,
                    withExtension: nil,
                    subdirectory: nil
                ),
                let source = try? String(contentsOf: url, encoding: .utf8) {
                    return source
                }
            }
        }

        return nil
    }

    private static func sourceDataFromBundle(
        _ bundle: Bundle,
        filePaths: [String]
    ) -> Data? {
        for sourcePath in filePaths {
            let normalized = normalizedResourcePath(sourcePath)
            let name = URL(fileURLWithPath: normalized).deletingPathExtension().lastPathComponent
            let fileExtension = URL(fileURLWithPath: normalized).pathExtension
            let directory = URL(fileURLWithPath: normalized).deletingLastPathComponent().path
            let directoryPath = directory == "." || directory.isEmpty ? nil : directory

            var candidateNames: [String] = [normalized]
            if fileExtension.isEmpty {
                candidateNames.append(name)
            }

            for candidate in candidateNames {
                let normalizedCandidate = normalizedResourcePath(candidate)
                let candidateExtension = URL(fileURLWithPath: normalizedCandidate).pathExtension
                let candidateName = URL(fileURLWithPath: normalizedCandidate)
                    .deletingPathExtension().lastPathComponent
                let candidateDirectory = URL(fileURLWithPath: normalizedCandidate)
                    .deletingLastPathComponent().path
                let lookupDirectory = candidateDirectory == "." || candidateDirectory.isEmpty
                    ? directoryPath
                    : candidateDirectory

                if let url = bundle.url(
                    forResource: candidateName,
                    withExtension: candidateExtension.isEmpty ? "svg" : candidateExtension,
                    subdirectory: lookupDirectory
                ),
                let data = try? Data(contentsOf: url) {
                    return data
                }

                if let url = bundle.url(
                    forResource: candidateName,
                    withExtension: nil,
                    subdirectory: lookupDirectory
                ),
                let data = try? Data(contentsOf: url) {
                    return data
                }

                if let url = bundle.url(
                    forResource: normalizedCandidate,
                    withExtension: nil,
                    subdirectory: nil
                ),
                let data = try? Data(contentsOf: url) {
                    return data
                }
            }
        }

        return nil
    }

    private static func sourceFromResourcePath(
        _ resourcePath: String,
        filePaths: [String]
    ) -> String? {
        for path in filePaths {
            let normalized = normalizedResourcePath(path)
            let candidatePaths = expandedResourcePaths(
                from: normalized,
                base: resourcePath
            )
            for candidatePath in candidatePaths {
                if let source = try? String(contentsOfFile: candidatePath, encoding: .utf8) {
                    return source
                }
            }
        }

        return nil
    }

    private static func sourceDataFromResourcePath(
        _ resourcePath: String,
        filePaths: [String]
    ) -> Data? {
        for path in filePaths {
            let normalized = normalizedResourcePath(path)
            let candidatePaths = expandedResourcePaths(
                from: normalized,
                base: resourcePath
            )
            for candidatePath in candidatePaths {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: candidatePath)) {
                    return data
                }
            }
        }

        return nil
    }

    private static func expandedResourcePaths(from path: String, base: String? = nil) -> [String] {
        let baseValue = base.flatMap { rawBasePath -> String? in
            let trimmed = normalizedResourcePath(rawBasePath)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let normalized = normalizedResourcePath(path)
        var candidates: [String] = []
        let appendCandidate: (String) -> Void = { value in
            if !value.isEmpty, !candidates.contains(value) {
                candidates.append(value)
            }
        }
        appendCandidate(normalized)
        if URL(fileURLWithPath: normalized).pathExtension.isEmpty {
            appendCandidate("\(normalized).svg")
        }

        if let baseValue {
            var basePathCandidates: [String] = []
            for candidate in candidates {
                basePathCandidates.append("\(baseValue)/\(candidate)")
                basePathCandidates.append("\(baseValue)/Resources/\(candidate)")
            }
            return basePathCandidates
        }

        return candidates
    }

    private static func normalizedResourcePath(_ path: String) -> String {
        var normalized = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")
        while normalized.hasPrefix("./") {
            normalized.removeFirst(2)
        }
        while normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    private static func missingResourceSource(for resourceName: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="35" viewBox="0 0 100 35">
            <rect width="100" height="35" fill="#fee2e2"/>
            <text x="4" y="20" font-size="8" fill="#991b1b">
                Missing resource: \(resourceName)
            </text>
        </svg>
        """
    }
}
