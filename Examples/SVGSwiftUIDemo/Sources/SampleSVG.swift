import Foundation

struct SampleSVG: Identifiable {
    let id: String
    let title: String
    let svg: String
    let defaultNodeID: String
}

enum DemoSamples {
    static let all: [SampleSVG] = [
        SampleSVG(
            id: "badge",
            title: "Badge",
            svg: """
            <svg width="120" height="120" viewBox="0 0 120 120">
              <g id="badge-group">
                <circle id="badge-ring" cx="60" cy="60" r="50" fill="#f5f5f5" stroke="#333333" stroke-width="4"/>
                <path id="main-path" d="M60 24 L72 48 L99 52 L79 72 L84 99 L60 86 L36 99 L41 72 L21 52 L48 48 Z" fill="#ff7a59"/>
              </g>
            </svg>
            """,
            defaultNodeID: "main-path"
        ),
        SampleSVG(
            id: "panel",
            title: "Panel",
            svg: """
            <svg width="180" height="120" viewBox="0 0 180 120">
              <rect id="panel-base" x="12" y="12" width="156" height="96" fill="#e2ecff" stroke="#3056d3" stroke-width="3"/>
              <line id="panel-divider" x1="12" y1="60" x2="168" y2="60" stroke="#3056d3" stroke-width="2"/>
              <circle id="panel-dot" cx="36" cy="36" r="8" fill="#3056d3"/>
            </svg>
            """,
            defaultNodeID: "panel-base"
        ),
        SampleSVG(
            id: "route",
            title: "Route",
            svg: """
            <svg width="180" height="120" viewBox="0 0 180 120">
              <polyline id="route-line" points="20,100 60,30 100,80 150,20" fill="none" stroke="#0f766e" stroke-width="8"/>
              <polygon id="route-arrow" points="150,20 136,24 142,36" fill="#0f766e"/>
            </svg>
            """,
            defaultNodeID: "route-line"
        ),
    ]
}
