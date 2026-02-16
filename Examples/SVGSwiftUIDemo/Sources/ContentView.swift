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
    private var animatedSamples: [SampleSVG] {
        samples.filter { $0.animation.isAnimated }
    }
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

            catalogRoot(for: .animation)
                .tabItem {
                    Label("애니메이션", systemImage: "arrow.clockwise")
                }
                .tag(DemoCatalogMode.animation)
                .accessibilityIdentifier("demo.tab.animation")

            catalogRoot(for: .w3c)
                .tabItem {
                    Label("W3C 케이스", systemImage: "checkmark.seal")
                }
                .tag(DemoCatalogMode.w3c)
                .accessibilityIdentifier("demo.tab.w3c")

            catalogRoot(for: .remote)
                .tabItem {
                    Label("원격 SVG", systemImage: "link")
                }
                .tag(DemoCatalogMode.remote)
                .accessibilityIdentifier("demo.tab.remote")
        }
    }

    private func samples(for mode: DemoCatalogMode) -> [SampleSVG] {
        switch mode {
        case .all:
            return samples
        case .animation:
            return animatedSamples
        case .w3c:
            return DemoSamples.w3cCatalogSamples
        case .remote:
            return []
        }
    }

    @ViewBuilder
    private func catalogRoot(for mode: DemoCatalogMode) -> some View {
        if mode == .remote {
            if horizontalSizeClass == .regular {
                NavigationView {
                    remoteSVGValidationView
                        .accessibilityIdentifier("demo.content.remote")
                }
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
            } else {
                NavigationView {
                    remoteSVGValidationView
                        .accessibilityIdentifier("demo.content.remote")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        } else if horizontalSizeClass == .regular {
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

    
    private func demoSampleList(for mode: DemoCatalogMode) -> some View {
        let sampleSet = samples(for: mode)
        let listTitle = mode.navigationTitle
        let sectionTitle = mode.sectionTitle
        let description = mode.sectionDescription
        let contentIdentifier: String
        switch mode {
        case .all:
            contentIdentifier = "demo.content"
        case .animation:
            contentIdentifier = "demo.content.animation"
        case .w3c:
            contentIdentifier = "demo.content.w3c"
        case .remote:
            contentIdentifier = "demo.content.remote"
        }

        return List {
            Section(header: Text(listTitle)) {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
            }

            Section(sectionTitle) {
                ForEach(sampleSet) { sample in
                    sampleListRow(for: sample, shouldFitCanvasToViewport: mode == .w3c)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(mode.navigationTitle)
        .accessibilityIdentifier(contentIdentifier)
    }

    private func sampleListRow(
        for sample: SampleSVG,
        shouldFitCanvasToViewport: Bool = false
    ) -> some View {
        NavigationLink(
            destination: sampleDetail(
                for: sample,
                shouldFitCanvasToViewport: shouldFitCanvasToViewport
            )
        ) {
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

    private func sampleDetail(
        for sample: SampleSVG,
        shouldFitCanvasToViewport: Bool = false
    ) -> some View {
        let useTimeline = runningAnimations.contains(sample.id)
        if useTimeline {
            return AnyView(
                GeometryReader { proxy in
                    TimelineView(.animation) { timeline in
                        sampleDetailContent(
                            for: sample,
                            at: timeline.date.timeIntervalSinceReferenceDate,
                            shouldFitCanvasToViewport: shouldFitCanvasToViewport,
                            containerSize: proxy.size
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("demo.sampleDetail.\(sample.id)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .navigationTitle(sample.title)
                    .navigationBarTitleDisplayMode(.inline)
                }
            )
        }

        return AnyView(
            GeometryReader { proxy in
                ScrollView {
                    sampleDetailContent(
                        for: sample,
                        at: 0.0,
                        shouldFitCanvasToViewport: shouldFitCanvasToViewport,
                        containerSize: proxy.size
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier("demo.sampleDetail.\(sample.id)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .navigationTitle(sample.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        )
    }

    private func sampleDetailContent(
        for sample: SampleSVG,
        at timestamp: TimeInterval,
        shouldFitCanvasToViewport: Bool,
        containerSize: CGSize
    ) -> some View {
        let configuration = renderConfiguration(for: sample, at: timestamp)
        let sourceData = DemoSamples.sourceData(for: sample)
        let sourceText = DemoSamples.source(for: sample)
        let sampleNodeState = nodeOverrideStates[sample.id, default: DemoNodeOverrideState(selectedTargetID: sample.defaultNodeID)]
        let preferredCanvasSize = DemoSamples.preferredCanvasSize(for: sample) ?? CGSize(width: 240, height: 210)
        let defaultCanvasSize = shouldFitCanvasToViewport
            ? fittedCanvasSize(for: preferredCanvasSize, containerWidth: containerSize.width)
            : preferredCanvasSize

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
            .frame(width: defaultCanvasSize.width, height: defaultCanvasSize.height)
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

    private func fittedCanvasSize(for sourceSize: CGSize, containerWidth: CGFloat) -> CGSize {
        let horizontalMargin: CGFloat = 32
        let availableWidth = max(containerWidth - horizontalMargin, 1)
        let widthScale = availableWidth / sourceSize.width
        let screenHeight = UIScreen.main.bounds.height
        let availableHeight = max(screenHeight - 360, 1)
        let heightScale = availableHeight / sourceSize.height
        let scale = min(widthScale, heightScale)

        if scale.isFinite && scale > 0 {
            return CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        }

        return sourceSize
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

    @ViewBuilder
    private var remoteSVGValidationView: some View {
        RemoteSVGValidationView(parserOptions: demoSVGRenderOptions)
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

private struct RemoteSVGValidationView: View {
    let parserOptions: SVGParserOptions

    @State private var urlText: String = "https://"
    @State private var errorMessage: String?
    @State private var fetchedURL: String?
    @State private var svgText: String = ""
    @State private var svgData: Data?
    @State private var isLoading: Bool = false
    @State private var sourceExpanded: Bool = false
    @State private var lastLoadedAt: Date?
    @State private var cachedSVG: [String: Data] = [:]
    @State private var cachedSource: [String: String] = [:]

    private let loader: URLSession = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            List {
                Section("운영 URL 입력") {
                    TextField("예: https://example.com/asset.svg", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .accessibilityIdentifier("demo.remote.urlField")

                    HStack {
                        Button("SVG 불러오기", action: {
                            Task { await loadRemoteSVG() }
                        })
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)
                        .accessibilityIdentifier("demo.remote.loadButton")

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section("오류") {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.vertical, 4)
                            .accessibilityIdentifier("demo.remote.error")
                    }
                }

                if let urlValue = fetchedURL, let currentData = svgData {
                    Section("렌더링") {
                        Text("요청 URL: \(urlValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("용량: \(currentData.count) bytes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let lastLoadedAt {
                            Text("마지막 로드: \(lastLoadedAt.formatted(date: .numeric, time: .standard))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        SVGView(
                            source: .data(currentData),
                            options: parserOptions
                        )
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 360)
                        .background(Color(white: 0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .accessibilityIdentifier("demo.remote.canvas")
                    }

                    Section("SVG 소스") {
                        DisclosureGroup(
                            "원본 소스 열기/접기",
                            isExpanded: $sourceExpanded
                        ) {
                            Text(svgText)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                                .accessibilityIdentifier("demo.remote.source")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("원격 SVG")
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.top, 2)
    }

    private var normalizedURLText: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func loadRemoteSVG() async {
        let trimmedURL = normalizedURLText
        guard !trimmedURL.isEmpty else {
            errorMessage = "URL을 입력해 주세요."
            svgData = nil
            svgText = ""
            fetchedURL = nil
            return
        }
        guard let remoteURL = URL(string: trimmedURL) else {
            errorMessage = "유효하지 않은 URL 형식입니다."
            svgData = nil
            svgText = ""
            fetchedURL = nil
            return
        }

        isLoading = true
        errorMessage = nil
        sourceExpanded = false

        if let cachedSVGData = cachedSVG[remoteURL.absoluteString],
           let cachedSourceText = cachedSource[remoteURL.absoluteString] {
            svgData = cachedSVGData
            svgText = cachedSourceText
            fetchedURL = remoteURL.absoluteString
            lastLoadedAt = Date()
            isLoading = false
            return
        }

        do {
            let (data, response) = try await loader.data(from: remoteURL)
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "HTTP \(httpResponse.statusCode): 응답 상태가 유효하지 않습니다."
                    svgData = nil
                    svgText = ""
                    fetchedURL = nil
                    isLoading = false
                    return
                }
            }
            let decodedSource = decodeSVGText(from: data)
            if decodedSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "SVG 텍스트를 추출할 수 없습니다."
                svgData = nil
                svgText = ""
                fetchedURL = nil
                isLoading = false
                return
            }

            cachedSVG[remoteURL.absoluteString] = data
            cachedSource[remoteURL.absoluteString] = decodedSource
            fetchedURL = remoteURL.absoluteString
            svgData = data
            svgText = decodedSource
            lastLoadedAt = Date()
            isLoading = false
        } catch {
            errorMessage = "요청 실패: \(error.localizedDescription)"
            svgData = nil
            svgText = ""
            fetchedURL = nil
            isLoading = false
        }
    }

    private func decodeSVGText(from data: Data) -> String {
        if let utf8Text = String(data: data, encoding: .utf8) {
            return utf8Text
        }
        if let utf16Text = String(data: data, encoding: .utf16) {
            return utf16Text
        }
        if let utf16LittleEndian = String(data: data, encoding: .utf16LittleEndian) {
            return utf16LittleEndian
        }
        if let utf16BigEndian = String(data: data, encoding: .utf16BigEndian) {
            return utf16BigEndian
        }
        return String(decoding: data, as: UTF8.self)
    }
}

private enum DemoCatalogMode: Int, CaseIterable {
    case all
    case animation
    case w3c
    case remote

    var navigationTitle: String {
        switch self {
        case .all:
            return "SVGSwiftUI Demo"
        case .animation:
            return "애니메이션"
        case .w3c:
            return "W3C 케이스"
        case .remote:
            return "원격 SVG"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all:
            return "SVG 샘플 목록"
        case .animation:
            return "애니메이션 샘플"
        case .w3c:
            return "W3C 검증 샘플"
        case .remote:
            return "원격 SVG"
        }
    }

    var sectionDescription: String {
        switch self {
        case .all:
            return "샘플 제목을 선택하면 렌더링, 애니메이션, 노드 제어, 소스 코드를 확인할 수 있습니다."
        case .animation:
            return "미리 구성된 애니메이션 샘플만 모아 놓아 동작 확인에 집중할 수 있습니다."
        case .w3c:
            return "단위 테스트 기반 W3C 시나리오 후보 샘플을 확인할 수 있습니다."
        case .remote:
            return "운영 URL로 SVG를 직접 받아 렌더링해 차이를 점검할 수 있습니다."
        }
    }
}

#Preview {
    ContentView()
}
