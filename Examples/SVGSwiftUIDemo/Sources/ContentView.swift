import Foundation
import SVGSwiftUI
import SwiftUI

private enum DemoColorChoice: Int, CaseIterable, Identifiable {
    case none
    case red
    case green
    case blue
    case magenta
    case cyan
    case yellow

    var id: Int { rawValue }

    var accessibilityIdentifier: String {
        switch self {
        case .none: return "none"
        case .red: return "red"
        case .green: return "green"
        case .blue: return "blue"
        case .magenta: return "magenta"
        case .cyan: return "cyan"
        case .yellow: return "yellow"
        }
    }

    var displayName: String {
        switch self {
        case .none: return "기본"
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .yellow: return "Yellow"
        }
    }

    var paint: SVGPaint? {
        switch self {
        case .none:
            return nil
        case .red:
            return .color(SVGColor(red: 0.94, green: 0.11, blue: 0.11, alpha: 1.0))
        case .green:
            return .color(SVGColor(red: 0.06, green: 0.76, blue: 0.21, alpha: 1.0))
        case .blue:
            return .color(SVGColor(red: 0.17, green: 0.45, blue: 0.98, alpha: 1.0))
        case .magenta:
            return .color(SVGColor(red: 0.84, green: 0.22, blue: 0.82, alpha: 1.0))
        case .cyan:
            return .color(SVGColor(red: 0.00, green: 0.79, blue: 0.87, alpha: 1.0))
        case .yellow:
            return .color(SVGColor(red: 0.98, green: 0.85, blue: 0.13, alpha: 1.0))
        }
    }

    var swatchColor: Color {
        switch self {
        case .none: return Color.gray
        case .red: return Color.red
        case .green: return Color.green
        case .blue: return Color.blue
        case .magenta: return Color.pink
        case .cyan: return Color.cyan
        case .yellow: return Color.yellow
        }
    }
}

private struct DemoNodeOverrideState: Equatable {
    var isEnabled: Bool
    var selectedTargetID: String
    var fillChoice: DemoColorChoice
    var strokeChoice: DemoColorChoice
    var scale: Double
    var offsetX: Double
    var offsetY: Double
    var opacity: Double

    init(selectedTargetID: String) {
        self.isEnabled = false
        self.selectedTargetID = selectedTargetID
        self.fillChoice = .none
        self.strokeChoice = .none
        self.scale = 1.0
        self.offsetX = 0.0
        self.offsetY = 0.0
        self.opacity = 1.0
    }
}

private struct DemoNodeOverride {
    let nodeID: String
    let override: NodeOverride
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let samples = DemoSamples.all
    private let demoSVGRenderOptions = SVGParserOptions(
        enableStyleTag: true,
        enableDataURI: false,
        imageNodePolicy: .ignore
    )

    @State private var selectedCatalog: DemoCatalogMode = .all
    @State private var expandedSources: Set<String> = []
    @State private var runningAnimations: Set<String> = {
        let animatedSamples = DemoSamples.all.filter { $0.animation.isAnimated }
        return Set<String>(animatedSamples.map(\.id))
    }()
    @State private var nodeOverrideStates: [String: DemoNodeOverrideState] = Self.makeInitialNodeOverrideStates()

    var body: some View {
        TabView(selection: $selectedCatalog) {
            catalogRoot(for: .all)
                .tabItem {
                    Label("Demo 샘플", systemImage: "square.stack.3d.up")
                }
                .tag(DemoCatalogMode.all)
                .accessibilityIdentifier("demo.tab.samples")

            catalogRoot(for: .w3c)
                .tabItem {
                    Label("W3C 케이스", systemImage: "checkmark.seal")
                }
                .tag(DemoCatalogMode.w3c)
                .accessibilityIdentifier("demo.tab.w3c")
        }
    }

    private func samples(for mode: DemoCatalogMode) -> [SampleSVG] {
        switch mode {
        case .all:
            return samples
        case .w3c:
            return DemoSamples.w3cCatalogSamples
        }
    }

    @ViewBuilder
    private func catalogRoot(for mode: DemoCatalogMode) -> some View {
        if horizontalSizeClass == .regular {
            NavigationView {
                demoSampleList(for: mode)
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        } else {
            NavigationView {
                demoSampleList(for: mode)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    @ViewBuilder
    private func demoSampleList(for mode: DemoCatalogMode) -> some View {
        let sampleSet = samples(for: mode)
        let listTitle = mode.navigationTitle
        let sectionTitle = mode.sectionTitle
        let description = mode.sectionDescription
        let contentIdentifier = mode == .all
            ? "demo.content"
            : "demo.content.w3c"

        List {
            Section(header: Text(listTitle)) {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
            }

            Section(sectionTitle) {
                ForEach(sampleSet) { sample in
                    sampleListRow(for: sample)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(mode.navigationTitle)
        .accessibilityIdentifier(contentIdentifier)
    }

    private func sampleListRow(for sample: SampleSVG) -> some View {
        NavigationLink(destination: sampleDetail(for: sample)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sample.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(sample.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(sample.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("demo.sampleRow.\(sample.id)")
    }

    private func sampleDetail(for sample: SampleSVG) -> some View {
        let useTimeline = runningAnimations.contains(sample.id)
        if useTimeline {
            return AnyView(
                TimelineView(.animation) { timeline in
                    sampleDetailContent(for: sample, at: timeline.date.timeIntervalSinceReferenceDate)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("demo.sampleDetail.\(sample.id)")
                }
                .navigationTitle(sample.title)
                .navigationBarTitleDisplayMode(.inline)
            )
        }

        return AnyView(
            ScrollView {
                sampleDetailContent(for: sample, at: 0.0)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier("demo.sampleDetail.\(sample.id)")
            }
            .navigationTitle(sample.title)
            .navigationBarTitleDisplayMode(.inline)
        )
    }

    private func sampleDetailContent(for sample: SampleSVG, at timestamp: TimeInterval) -> some View {
        let configuration = renderConfiguration(for: sample, at: timestamp)
        let sourceData = DemoSamples.sourceData(for: sample)
        let sourceText = DemoSamples.source(for: sample)
        let sampleNodeState = nodeOverrideStates[sample.id, default: DemoNodeOverrideState(selectedTargetID: sample.defaultNodeID)]
        let preferredCanvasSize = DemoSamples.preferredCanvasSize(for: sample)
        let canvasWidth = preferredCanvasSize?.width ?? 240
        let canvasHeight = preferredCanvasSize?.height ?? 210

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(sample.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(sample.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(sample.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SVGView(
                source: .data(sourceData),
                options: demoSVGRenderOptions,
                configuration: configuration
            )
            .frame(width: canvasWidth, height: canvasHeight)
            .background(Color(white: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(sample.title) canvas")
            .accessibilityIdentifier("demo.canvas.\(sample.id)")

            if sample.animation != .none {
                Toggle("애니메이션 재생", isOn: animationEnabledBinding(for: sample.id))
                    .font(.caption)
                    .accessibilityIdentifier("demo.animationToggle.\(sample.id)")
                    .toggleStyle(.switch)
            }

            if !sample.overrideTargets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle(
                            "노드 오버라이드",
                            isOn: nodeOverrideEnabledBinding(for: sample)
                        )
                        .font(.caption)
                        .accessibilityIdentifier("demo.nodeOverrideEnabled.\(sample.id)")
                        Spacer()
                        Text("\(sample.overrideTargets.count)개 대상")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Picker("타겟 노드", selection: binding(for: sample, keyPath: \.selectedTargetID)) {
                        ForEach(sample.overrideTargets, id: \.self) { targetID in
                            Text(targetID)
                                .font(.caption)
                                .tag(targetID)
                                .accessibilityIdentifier("demo.nodeTargetOption.\(sample.id).\(targetID)")
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!sampleNodeState.isEnabled)
                    .font(.caption)
                    .accessibilityIdentifier("demo.nodeTargetPicker.\(sample.id)")

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Fill")
                                .font(.caption)
                            Spacer()
                            Text(sampleNodeState.fillChoice.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        nodeColorOptionRow(
                            sampleID: sample.id,
                            selected: sampleNodeState.fillChoice,
                            optionIdentifierPrefix: "demo.nodeFillOption",
                            isEnabled: sampleNodeState.isEnabled,
                            onSelect: { choice in
                                binding(for: sample, keyPath: \.fillChoice).wrappedValue = choice
                            }
                        )
                        .disabled(!sampleNodeState.isEnabled)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Stroke")
                                .font(.caption)
                            Spacer()
                            Text(sampleNodeState.strokeChoice.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        nodeColorOptionRow(
                            sampleID: sample.id,
                            selected: sampleNodeState.strokeChoice,
                            optionIdentifierPrefix: "demo.nodeStrokeOption",
                            isEnabled: sampleNodeState.isEnabled,
                            onSelect: { choice in
                                binding(for: sample, keyPath: \.strokeChoice).wrappedValue = choice
                            }
                        )
                        .disabled(!sampleNodeState.isEnabled)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scale: \(formatted(sampleNodeState.scale))")
                            .font(.caption2)
                        Slider(
                            value: binding(for: sample, keyPath: \.scale),
                            in: 0.5...2.5,
                            step: 0.05
                        )
                        .disabled(!sampleNodeState.isEnabled)
                        .accessibilityIdentifier("demo.nodeScale.\(sample.id)")
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Offset X: \(formatted(sampleNodeState.offsetX))")
                                .font(.caption2)
                            Slider(
                                value: binding(for: sample, keyPath: \.offsetX),
                                in: -80...80,
                                step: 1
                            )
                            .disabled(!sampleNodeState.isEnabled)
                            .accessibilityIdentifier("demo.nodeOffsetX.\(sample.id)")
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Offset Y: \(formatted(sampleNodeState.offsetY))")
                                .font(.caption2)
                            Slider(
                                value: binding(for: sample, keyPath: \.offsetY),
                                in: -80...80,
                                step: 1
                            )
                            .disabled(!sampleNodeState.isEnabled)
                            .accessibilityIdentifier("demo.nodeOffsetY.\(sample.id)")
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Opacity: \(formatted(sampleNodeState.opacity))")
                            .font(.caption2)
                        Slider(
                            value: binding(for: sample, keyPath: \.opacity),
                            in: 0.2...1.0,
                            step: 0.05
                        )
                        .disabled(!sampleNodeState.isEnabled)
                        .accessibilityIdentifier("demo.nodeOpacity.\(sample.id)")
                    }
                }
            }

            DisclosureGroup(
                isExpanded: sourceExpandedBinding(for: sample.id),
                content: {
                    Text(sourceText)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                        .accessibilityIdentifier("demo.source.\(sample.id)")
                },
                label: {
                    Label("SVG 코드 보기", systemImage: "doc.plaintext")
                        .font(.caption)
                }
            )
            .accessibilityIdentifier("demo.codeDisclosure.\(sample.id)")
            .padding(.vertical, 4)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("demo.sampleRow.\(sample.id)")
        .id(sample.id)
    }

    private func renderConfiguration(for sample: SampleSVG, at timestamp: TimeInterval) -> SVGRenderConfiguration {
        let isAnimationEnabled = runningAnimations.contains(sample.id)
        let nodeState = nodeOverrideStates[sample.id, default: DemoNodeOverrideState(selectedTargetID: sample.defaultNodeID)]
        var overrides: NodeOverrideMap = [:]
        let controlOverride = controlNodeOverride(from: nodeState)

        if let control = controlOverride {
            if isAnimationEnabled {
                let animation = animationNodeOverride(for: sample, at: timestamp)
                if let animationTarget = animation?.nodeID,
                   animationTarget == control.nodeID {
                    let merged = mergedOverride(base: control.override, with: animation?.override)
                    overrides[control.nodeID] = merged
                } else {
                    overrides[control.nodeID] = control.override
                    if let animationTarget = animation?.nodeID,
                       let animationOverride = animation?.override {
                        overrides[animationTarget] = animationOverride
                    }
                }
            } else {
                overrides[control.nodeID] = control.override
            }
        } else if isAnimationEnabled, let animation = animationNodeOverride(for: sample, at: timestamp) {
            overrides[animation.nodeID] = animation.override
        }

        return SVGRenderConfiguration(idOverrides: overrides)
    }

    private func controlNodeOverride(from state: DemoNodeOverrideState) -> DemoNodeOverride? {
        if !state.isEnabled {
            return nil
        }

        let targetID = state.selectedTargetID
        var override = NodeOverride()
        let defaultScale = 1.0
        let defaultOffset = 0.0
        let defaultOpacity = 1.0
        let scaleDeltaTolerance = 0.001
        let offsetDeltaTolerance = 0.001

        if let fillPaint = state.fillChoice.paint {
            override.fill = fillPaint
        }
        if let strokePaint = state.strokeChoice.paint {
            override.stroke = strokePaint
        }

        let hasScaleChange = abs(state.scale - defaultScale) > scaleDeltaTolerance
        if hasScaleChange {
            override.scale = SVGSize(width: state.scale, height: state.scale)
        }

        let hasOffsetChangeX = abs(state.offsetX - defaultOffset) > offsetDeltaTolerance
        let hasOffsetChangeY = abs(state.offsetY - defaultOffset) > offsetDeltaTolerance
        if hasOffsetChangeX || hasOffsetChangeY {
            override.offset = SVGPoint(x: state.offsetX, y: state.offsetY)
        }

        let hasOpacityChange = abs(state.opacity - defaultOpacity) > offsetDeltaTolerance
        if hasOpacityChange {
            override.opacity = state.opacity
        }

        if override.fill == nil,
           override.stroke == nil,
           override.scale == nil,
           override.offset == nil,
           override.opacity == nil {
            return nil
        }

        return DemoNodeOverride(nodeID: targetID, override: override)
    }

    private func animationNodeOverride(for sample: SampleSVG, at timestamp: TimeInterval) -> DemoNodeOverride? {
        if sample.animation == .none {
            return nil
        }

        let progress = animationProgress(for: timestamp, duration: animationDuration(sample: sample))

        switch sample.animation {
        case .none:
            return nil
        case let .pulse(nodeID, minScale, maxScale, duration):
            guard duration > 0.0 else { return nil }
            let scale = minScale + ((maxScale - minScale) * progress)
            return DemoNodeOverride(
                nodeID: nodeID,
                override: NodeOverride(scale: SVGSize(width: scale, height: scale))
            )
        case let .drift(nodeID, offsetX, offsetY, duration):
            guard duration > 0.0 else { return nil }
            let phaseOffset = (progress - 0.5) * 2.0
            return DemoNodeOverride(
                nodeID: nodeID,
                override: NodeOverride(offset: SVGPoint(x: offsetX * phaseOffset, y: offsetY * phaseOffset))
            )
        case let .opacity(nodeID, minOpacity, maxOpacity, duration):
            guard duration > 0.0 else { return nil }
            let alpha = minOpacity + ((maxOpacity - minOpacity) * progress)
            return DemoNodeOverride(nodeID: nodeID, override: NodeOverride(opacity: alpha))
        }
    }

    private func animationDuration(sample: SampleSVG) -> Double {
        switch sample.animation {
        case .none: return 0.1
        case let .pulse(_, _, _, duration): return duration
        case let .drift(_, _, _, duration): return duration
        case let .opacity(_, _, _, duration): return duration
        }
    }

    private func mergedOverride(base: NodeOverride, with animation: NodeOverride?) -> NodeOverride {
        guard let animation = animation else {
            return base
        }

        var merged = base
        if merged.fill == nil {
            merged.fill = animation.fill
        }
        if merged.stroke == nil {
            merged.stroke = animation.stroke
        }
        if merged.strokeWidth == nil {
            merged.strokeWidth = animation.strokeWidth
        }
        if merged.opacity == nil {
            merged.opacity = animation.opacity
        }
        if merged.scale == nil {
            merged.scale = animation.scale
        }
        if let baseOffset = merged.offset {
            if let animationOffset = animation.offset {
                let mergedOffsetX: Double = baseOffset.x + animationOffset.x
                let mergedOffsetY: Double = baseOffset.y + animationOffset.y
                merged.offset = SVGPoint(x: mergedOffsetX, y: mergedOffsetY)
            }
        } else {
            merged.offset = animation.offset
        }
        return merged
    }

    private func animationProgress(for timestamp: TimeInterval, duration: Double) -> Double {
        let safeDuration = max(duration, 0.1)
        let normalized = timestamp.truncatingRemainder(dividingBy: safeDuration) / safeDuration
        let phase = normalized * 2.0 * Double.pi
        let sineValue = sin(phase)
        return (sineValue + 1.0) / 2.0
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private func nodeColorOptionRow(
        sampleID: String,
        selected: DemoColorChoice,
        optionIdentifierPrefix: String,
        isEnabled: Bool,
        onSelect: @escaping (DemoColorChoice) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DemoColorChoice.allCases) { choice in
                    let isSelected = (choice == selected)
                    Button(action: {
                        onSelect(choice)
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(choice.swatchColor)
                                .frame(width: 10, height: 10)
                            Text(choice.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(minHeight: 28)
                        .background(
                            isSelected
                                ? Color.accentColor.opacity(0.2)
                                : Color(uiColor: UIColor.secondarySystemBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                                    lineWidth: isSelected ? 1.4 : 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                    .accessibilityIdentifier(
                        "\(optionIdentifierPrefix).\(sampleID).\(choice.accessibilityIdentifier)"
                    )
                }
            }
        }
    }

    private func sourceExpandedBinding(for sampleID: String) -> Binding<Bool> {
        Binding(
            get: { expandedSources.contains(sampleID) },
            set: { isExpanded in
                if isExpanded {
                    expandedSources.insert(sampleID)
                } else {
                    expandedSources.remove(sampleID)
                }
            }
        )
    }

    private func animationEnabledBinding(for sampleID: String) -> Binding<Bool> {
        Binding(
            get: { runningAnimations.contains(sampleID) },
            set: { isEnabled in
                if isEnabled {
                    runningAnimations.insert(sampleID)
                } else {
                    runningAnimations.remove(sampleID)
                }
            }
        )
    }

    private func nodeOverrideEnabledBinding(for sample: SampleSVG) -> Binding<Bool> {
        Binding(
            get: {
                let state = self.nodeOverrideStates[sample.id]
                return state?.isEnabled ?? false
            },
            set: { isEnabled in
                var nextState = self.nodeOverrideStates[sample.id] ?? DemoNodeOverrideState(selectedTargetID: sample.defaultNodeID)
                let safeTarget = stateTarget(for: sample, preferred: nextState.selectedTargetID)
                nextState.selectedTargetID = safeTarget
                nextState.isEnabled = isEnabled
                self.nodeOverrideStates[sample.id] = nextState
            }
        )
    }

    private func binding<Value>(
        for sample: SampleSVG,
        keyPath: WritableKeyPath<DemoNodeOverrideState, Value>
    ) -> Binding<Value> {
        let fallbackState = DemoNodeOverrideState(selectedTargetID: sample.defaultNodeID)
        return Binding(
            get: {
                let state = self.nodeOverrideStates[sample.id] ?? fallbackState
                return state[keyPath: keyPath]
            },
            set: { newValue in
                var nextState = self.nodeOverrideStates[sample.id] ?? fallbackState
                let safeTarget = stateTarget(for: sample, preferred: nextState.selectedTargetID)
                nextState.selectedTargetID = safeTarget
                nextState[keyPath: keyPath] = newValue
                self.nodeOverrideStates[sample.id] = nextState
            }
        )
    }

    private func stateTarget(for sample: SampleSVG, preferred: String) -> String {
        if sample.overrideTargets.isEmpty {
            return sample.defaultNodeID
        }
        if sample.overrideTargets.contains(preferred) {
            return preferred
        }
        return sample.overrideTargets[0]
    }

    @MainActor
    private static func makeInitialNodeOverrideStates() -> [String: DemoNodeOverrideState] {
        var states: [String: DemoNodeOverrideState] = [:]
        for sample in DemoSamples.all {
            let defaultTarget = sample.overrideTargets.first ?? sample.defaultNodeID
            states[sample.id] = DemoNodeOverrideState(selectedTargetID: defaultTarget)
        }
        return states
    }
}

private enum DemoCatalogMode: Int, CaseIterable {
    case all
    case w3c

    var navigationTitle: String {
        switch self {
        case .all:
            return "SVGSwiftUI Demo"
        case .w3c:
            return "W3C 케이스"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all:
            return "SVG 샘플 목록"
        case .w3c:
            return "W3C 검증 샘플"
        }
    }

    var sectionDescription: String {
        switch self {
        case .all:
            return "샘플 제목을 선택하면 렌더링, 애니메이션, 노드 제어, 소스 코드를 확인할 수 있습니다."
        case .w3c:
            return "단위 테스트 기반 W3C 시나리오 후보 샘플을 확인할 수 있습니다."
        }
    }
}

#Preview {
    ContentView()
}
