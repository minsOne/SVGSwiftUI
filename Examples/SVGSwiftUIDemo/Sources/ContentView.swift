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

            catalogRoot(for: .smil)
                .tabItem {
                    Label("SMIL", systemImage: "timeline")
                }
                .tag(DemoCatalogMode.smil)
                .accessibilityIdentifier("demo.tab.smil")

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
        case .smil:
            return DemoSamples.smilSamples
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
        case .smil:
            contentIdentifier = "demo.content.smil"
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

            ZStack {
                Color(white: 0.97)
                    .accessibilityHidden(true)
                SVGView(
                    source: .data(sourceData),
                    options: demoSVGRenderOptions,
                    configuration: configuration
                )
            }
            .frame(width: defaultCanvasSize.width, height: defaultCanvasSize.height)
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

    private struct RemoteSVGPreset: Identifiable {
        let id: String
        let title: String
        let url: String
        let note: String
    }

    private struct RemotePresetRenderState {
        var isLoading: Bool = false
        var isDownloadComplete: Bool = false
        var sourceText: String = ""
        var data: Data?
        var analysis: RemoteSMILAnalysis?
        var lastLoadedAt: Date?
        var error: String?
    }

    private struct RemoteSMILAnalysis {
        enum SupportStatus {
            case noSMILElements
            case fullySupported
            case partialSupported
            case unsupportedElements
            case parseFailed(String)
        }

        let status: SupportStatus
        let sourceSMILElementCount: Int
        let sourceCSSAnimationDetected: Bool
        let sourceJavaScriptDetected: Bool
        let parsedAnimationCount: Int
        let unsupportedSmilElementKeys: [String]
        let unsupportedSmilAttributeKeys: [String]
        let unsupportedOtherKeys: [String]
        var statusText: String {
            switch status {
            case .noSMILElements where sourceJavaScriptDetected:
                return "SMIL 없음 / JS 기반 애니메이션"
            case .noSMILElements where sourceCSSAnimationDetected:
                return "SMIL 없음 / CSS 기반 애니메이션"
            case .noSMILElements:
                return "SMIL 요소 미탐지"
            case .fullySupported:
                return "SMIL 파싱됨 / 지원 가능성 높음"
            case .partialSupported:
                return "SMIL 일부 폴백 예상"
            case .unsupportedElements:
                return "SMIL 요소 있으나 미지원/파싱 실패"
            case .parseFailed:
                return "네트워크 또는 파싱 실패"
            }
        }

        var statusColor: Color {
            switch status {
            case .fullySupported:
                return .green
            case .partialSupported:
                return .orange
            case .unsupportedElements:
                return .red
            case .noSMILElements:
                return .secondary
            case .parseFailed:
                return .red
            }
        }
    }

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
    @State private var cachedAnalyses: [String: RemoteSMILAnalysis] = [:]
    @State private var isBatchAnalyzing: Bool = false
    @State private var activeAnalysis: RemoteSMILAnalysis?
    @State private var presetRenderStates: [String: RemotePresetRenderState] = [:]
    @State private var isBatchDownloading: Bool = false
    @State private var selectedPresetID: String? = nil

    private let loader: URLSession = .shared
    private let remotePresets: [RemoteSVGPreset] = [
        RemoteSVGPreset(
            id: "svg-animated-loaders",
            title: "SVG Animated Loaders",
            url: "https://cdn.svgator.com/images/2023/03/svg-animated-loaders.svg",
            note: "SVGator 샘플. 실제로 SMIL 태그가 거의 없어 CSS 기반으로 판단됨."
        ),
        RemoteSVGPreset(
            id: "simple-svg-animated-loaders",
            title: "Simple SVG Animated Loaders",
            url: "https://cdn.svgator.com/images/2023/03/simple-svg-animated-loaders.svg",
            note: "SVGator 샘플. SMIL 태그 확인이 필요해 추가함."
        ),
        RemoteSVGPreset(
            id: "stopwatch-svg-animation",
            title: "Stopwatch SVG Animation",
            url: "https://cdn.svgator.com/images/2023/03/stopwatch-svg-animation.svg",
            note: "SVGator 샘플. SMIL 사용 여부를 먼저 점검 후 렌더링."
        ),
        RemoteSVGPreset(
            id: "cool-shapes-animated-using-svg",
            title: "Cool Shapes Animated Using SVG",
            url: "https://cdn.svgator.com/images/2023/03/cool-shapes-animated-using-svg.svg",
            note: "지형/도형 애니메이션. CSS 기반일 가능성 큼."
        ),
        RemoteSVGPreset(
            id: "animated-geometric-shapes-background",
            title: "Animated Geometric Shapes Background",
            url: "https://cdn.svgator.com/images/2023/03/animated-geometric-shapes-background.svg",
            note: "배경형 움직임 샘플. SMIL 미탐색 시도 용도."
        ),
        RemoteSVGPreset(
            id: "js-svg-animated-geometric-objects-background",
            title: "JS SVG Animated Geometric Objects Background",
            url: "https://cdn.svgator.com/images/2023/03/js-svg-animated-geometric-objects-background.svg",
            note: "이름상 JS/애니메이션 기반 샘플. SMIL 동작 미포함 가능성이 높음."
        ),
        RemoteSVGPreset(
            id: "animated-skating-girls",
            title: "Animated Skating Girls",
            url: "https://cdn.svgator.com/images/2023/03/animated-skating-girls.svg",
            note: "캐릭터형 샘플. 스타일/키프레임 위주인지 확인."
        ),
        RemoteSVGPreset(
            id: "animated-js-svg-example",
            title: "Animated JS SVG Example",
            url: "https://cdn.svgator.com/images/2023/03/animated-js-svg-example.svg",
            note: "자바스크립트 명시명이지만 SVG 내 애니메이션 태그 중심으로 점검."
        ),
        RemoteSVGPreset(
            id: "animated-parrot-logo",
            title: "Animated Parrot Logo",
            url: "https://cdn.svgator.com/images/2023/03/animated-parrot-logo.svg",
            note: "로고형 애니메이션 샘플."
        ),
        RemoteSVGPreset(
            id: "musicat-animated-logo-example",
            title: "Musicat Animated Logo",
            url: "https://cdn.svgator.com/images/2023/03/musicat-animated-logo-example.svg",
            note: "로고형 애니메이션 샘플."
        ),
        RemoteSVGPreset(
            id: "simple-animated-toggle-buttons",
            title: "Simple Animated Toggle Buttons",
            url: "https://cdn.svgator.com/images/2023/03/simple-animated-toggle-buttons.svg",
            note: "토글형 UI형 샘플. SMIL 태그 존재 여부 먼저 점검."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            List {
                Section("추천 SVGator 샘플") {
                    HStack {
                        Text("원격 샘플을 탭하면 즉시 렌더링됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(isBatchAnalyzing ? "분석 중..." : "일괄 지원성 분석") {
                            Task { await analyzeAllRemotePresets() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isBatchAnalyzing)
                        .accessibilityIdentifier("demo.remote.batchAnalyze")
                    }
                    ForEach(remotePresets) { preset in
                        let state = presetRenderStates[preset.url]
                        let isSelected = selectedPresetID == preset.id
                        let isPresetLoading = state?.isLoading == true

                        Button {
                            Task { await applyRemotePreset(preset) }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.title)
                                            .font(.callout)
                                            .fontWeight(.medium)
                                        Text(preset.note)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if let analysis = cachedAnalyses[preset.url] {
                                            Text(analysis.statusText)
                                                .font(.caption2)
                                                .foregroundStyle(analysis.statusColor)
                                        } else if isBatchAnalyzing {
                                            Text("일괄 분석 대기")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        } else if let message = state?.error {
                                            Text("다운로드 실패: \(message)")
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                        } else if state?.isDownloadComplete == true {
                                            Text("다운로드 완료")
                                                .font(.caption2)
                                                .foregroundStyle(.green)
                                        } else if isPresetLoading || isBatchDownloading {
                                            Text("다운로드 중...")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("탭해서 렌더링")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if isPresetLoading || (isSelected && isLoading) {
                                        ProgressView()
                                            .controlSize(.small)
                                            .tint(.blue)
                                    } else if state?.isDownloadComplete == true {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "arrow.down.circle")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }

                                Text(preset.url)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("demo.remote.presetRow.\(preset.id)")
                        .accessibilityHint("원격 SVG를 내려받아 렌더링 영역에 표시")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                        .background(
                            isSelected
                                ? Color.accentColor.opacity(0.08)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            Task { await preloadRemotePreset(preset) }
                        }
                    }
                }

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

                    Section("SMIL 지원성 분석") {
                        if let analysis = activeAnalysis {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SMIL 요소 감지: \(analysis.sourceSMILElementCount)개")
                                    .font(.caption)
                                    .foregroundStyle(analysis.sourceSMILElementCount == 0 ? .secondary : .primary)

                                Text("CSS 애니메이션 힌트: \(analysis.sourceCSSAnimationDetected ? "있음" : "없음")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("JavaScript 힌트: \(analysis.sourceJavaScriptDetected ? "있음" : "없음")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("파서 수집 애니메이션: \(analysis.parsedAnimationCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                switch analysis.status {
                                case .noSMILElements:
                                    Text("현재 파일은 SMIL 요소가 없고, CSS/기타 표현 기반 애니메이션으로 추정됩니다.")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                case .fullySupported:
                                    Text("SMIL 애니메이션이 수집되었고 미지원 요소는 없습니다.")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                case .partialSupported:
                                    Text("SMIL 요소가 있으나 일부 속성/요소는 미지원으로 폴백됩니다.")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                case .unsupportedElements:
                                    Text("SMIL 요소가 발견되었으나 파싱이 불안정합니다.")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                case .parseFailed(let description):
                                    Text("파싱 실패: \(description)")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }

                                if !analysis.unsupportedSmilElementKeys.isEmpty {
                                    let unsupportedSmilElements = analysis.unsupportedSmilElementKeys.joined(separator: ", ")
                                    Text("미지원 SMIL 요소 키: \(unsupportedSmilElements)")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }

                                if !analysis.unsupportedSmilAttributeKeys.isEmpty {
                                    let unsupportedSmilAttributes = analysis.unsupportedSmilAttributeKeys.joined(separator: ", ")
                                    Text("미지원 SMIL 속성 키: \(unsupportedSmilAttributes)")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }

                                if !analysis.unsupportedOtherKeys.isEmpty {
                                    let unsupportedOther = analysis.unsupportedOtherKeys.joined(separator: ", ")
                                    Text("기타 미지원 피처: \(unsupportedOther)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("아직 분석되지 않았습니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
            .task {
                await preloadAllRemotePresetsIfNeeded()
            }
        }
        .padding(.top, 2)
    }

    private var normalizedURLText: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func loadRemoteSVG(using overrideURL: String? = nil) async {
        let candidateURL = (overrideURL ?? normalizedURLText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidateURL.isEmpty else {
            errorMessage = "URL을 입력해 주세요."
            svgData = nil
            svgText = ""
            fetchedURL = nil
            activeAnalysis = nil
            return
        }
        guard let remoteURL = URL(string: candidateURL) else {
            errorMessage = "유효하지 않은 URL 형식입니다."
            svgData = nil
            svgText = ""
            fetchedURL = nil
            activeAnalysis = nil
            return
        }
        urlText = candidateURL

        isLoading = true
        errorMessage = nil
        sourceExpanded = false
        activeAnalysis = nil

        if let cachedSVGData = cachedSVG[remoteURL.absoluteString],
           let cachedSourceText = cachedSource[remoteURL.absoluteString] {
            svgData = cachedSVGData
            svgText = cachedSourceText
            fetchedURL = remoteURL.absoluteString
            activeAnalysis = cachedAnalyses[remoteURL.absoluteString]
            if activeAnalysis == nil {
                activeAnalysis = runSMILAnalysis(sourceText: cachedSourceText, data: cachedSVGData)
                if let analysis = activeAnalysis {
                    cachedAnalyses[remoteURL.absoluteString] = analysis
                }
            }
            lastLoadedAt = Date()
            isLoading = false
            return
        }

        do {
            let (data, decodedSource) = try await loadRemotePayload(from: remoteURL)

            cachedSVG[remoteURL.absoluteString] = data
            cachedSource[remoteURL.absoluteString] = decodedSource
            fetchedURL = remoteURL.absoluteString
            svgData = data
            svgText = decodedSource
            let analysis = runSMILAnalysis(sourceText: decodedSource, data: data)
            cachedAnalyses[remoteURL.absoluteString] = analysis
            activeAnalysis = analysis
            lastLoadedAt = Date()
            isLoading = false
        } catch {
            errorMessage = "요청 실패: \(error.localizedDescription)"
            svgData = nil
            svgText = ""
            fetchedURL = nil
            activeAnalysis = nil
            isLoading = false
        }
    }

    @MainActor
    private func analyzeAllRemotePresets() async {
        guard !isBatchAnalyzing else {
            return
        }
        isBatchAnalyzing = true
        defer { isBatchAnalyzing = false }

        for preset in remotePresets {
            if cachedAnalyses[preset.url] != nil {
                continue
            }

            guard let remoteURL = URL(string: preset.url) else {
                cachedAnalyses[preset.url] = RemoteSMILAnalysis(
                    status: .parseFailed("잘못된 URL 형식입니다."),
                    sourceSMILElementCount: 0,
                    sourceCSSAnimationDetected: false,
                    sourceJavaScriptDetected: false,
                    parsedAnimationCount: 0,
                    unsupportedSmilElementKeys: [],
                    unsupportedSmilAttributeKeys: [],
                    unsupportedOtherKeys: []
                )
                continue
            }

            do {
                let (data, sourceText) = try await loadRemotePayload(from: remoteURL)
                let analysis = runSMILAnalysis(sourceText: sourceText, data: data)
                let remoteKey = remoteURL.absoluteString
                cachedAnalyses[remoteKey] = analysis
                cachedSVG[remoteKey] = data
                cachedSource[remoteKey] = sourceText
            } catch {
                cachedAnalyses[preset.url] = RemoteSMILAnalysis(
                    status: .parseFailed(error.localizedDescription),
                    sourceSMILElementCount: 0,
                    sourceCSSAnimationDetected: false,
                    sourceJavaScriptDetected: false,
                    parsedAnimationCount: 0,
                    unsupportedSmilElementKeys: [],
                    unsupportedSmilAttributeKeys: [],
                    unsupportedOtherKeys: []
                )
            }
        }
    }

    @MainActor
    private func applyRemotePreset(_ preset: RemoteSVGPreset) async {
        selectedPresetID = preset.id
        await loadRemoteSVG(using: preset.url)
        if let cachedSourceText = cachedSource[preset.url],
           let cachedAnalysis = cachedAnalyses[preset.url] {
            svgText = cachedSourceText
            activeAnalysis = cachedAnalysis
        }
    }

    @MainActor
    private func preloadRemotePreset(_ preset: RemoteSVGPreset) async {
        guard let remoteURL = URL(string: preset.url) else {
            var state = presetRenderStates[preset.url] ?? RemotePresetRenderState()
            state.error = "유효하지 않은 URL 형식입니다."
            presetRenderStates[preset.url] = state
            return
        }

        let remoteKey = remoteURL.absoluteString
        if let cachedAnalysis = cachedAnalyses[remoteKey],
           let cachedSourceText = cachedSource[remoteKey],
           let cachedSVGData = cachedSVG[remoteKey],
           presetRenderStates[remoteKey]?.isDownloadComplete != false {
            let existing = presetRenderStates[remoteKey]
            if existing?.isDownloadComplete != true {
                presetRenderStates[remoteKey] = RemotePresetRenderState(
                    isLoading: false,
                    isDownloadComplete: true,
                    sourceText: cachedSourceText,
                    data: cachedSVGData,
                    analysis: cachedAnalysis,
                    lastLoadedAt: existing?.lastLoadedAt,
                    error: nil
                )
            }
            return
        }

        if presetRenderStates[remoteKey]?.isLoading == true || presetRenderStates[remoteKey]?.isDownloadComplete == true {
            return
        }

        var state = presetRenderStates[remoteKey] ?? RemotePresetRenderState()
        state.isLoading = true
        state.error = nil
        presetRenderStates[remoteKey] = state

        do {
            let (data, sourceText) = try await loadRemotePayload(from: remoteURL)
            let analysis = runSMILAnalysis(sourceText: sourceText, data: data)
            cachedAnalyses[remoteKey] = analysis
            cachedSource[remoteKey] = sourceText
            cachedSVG[remoteKey] = data

            let finishedState = RemotePresetRenderState(
                isLoading: false,
                isDownloadComplete: true,
                sourceText: sourceText,
                data: data,
                analysis: analysis,
                lastLoadedAt: Date(),
                error: nil
            )
            presetRenderStates[remoteKey] = finishedState
        } catch {
            var failedState = presetRenderStates[remoteKey] ?? RemotePresetRenderState()
            failedState.isLoading = false
            failedState.isDownloadComplete = false
            failedState.error = error.localizedDescription
            presetRenderStates[remoteKey] = failedState
        }
    }

    @MainActor
    private func preloadAllRemotePresetsIfNeeded() async {
        guard !isBatchDownloading else {
            return
        }
        isBatchDownloading = true
        defer { isBatchDownloading = false }

        for preset in remotePresets {
            await preloadRemotePreset(preset)
        }
    }

    private func loadRemotePayload(from remoteURL: URL) async throws -> (Data, String) {
        let (data, response) = try await loader.data(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw RemoteLoadError.httpStatus(httpResponse.statusCode)
            }
        }
        let decodedSource = decodeSVGText(from: data)
        if decodedSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw RemoteLoadError.emptyPayload
        }
        let resolvedURL = response.url ?? remoteURL
        let inlineAwareSource = await inlineExternalStylesheets(in: decodedSource, baseURL: resolvedURL)
        guard let encodedPayload = inlineAwareSource.data(using: .utf8) else {
            throw RemoteLoadError.encodingFailure
        }
        return (encodedPayload, inlineAwareSource)
    }

    private enum RemoteLoadError: LocalizedError {
        case httpStatus(Int)
        case emptyPayload
        case encodingFailure

        var errorDescription: String? {
            switch self {
            case let .httpStatus(code):
                return "HTTP \(code): 응답 상태가 유효하지 않습니다."
            case .emptyPayload:
                return "응답 본문이 비어 있어 분석할 수 없습니다."
            case .encodingFailure:
                return "응답 소스를 UTF-8로 변환하지 못했습니다."
            }
        }
    }

    private func runSMILAnalysis(sourceText: String, data: Data) -> RemoteSMILAnalysis {
        let lowerSource = sourceText.lowercased()
        let smilElementTags = detectSMILElementTags(from: lowerSource)
        let hasCSSAnimation = lowerSource.contains("@keyframes") || lowerSource.contains("animation:")
        let hasJavaScript = lowerSource.contains("<script") || lowerSource.contains("requestanimationframe")
        let unsupportedSmilElements = detectUnsupportedSMILElements(from: lowerSource)
        let parsedAnimationCount = detectSMILAnimations(from: lowerSource)

        let status: RemoteSMILAnalysis.SupportStatus = {
            if smilElementTags == 0 {
                return .noSMILElements
            }
            if parsedAnimationCount == 0 {
                return .unsupportedElements
            }
            if unsupportedSmilElements.isEmpty {
                return .fullySupported
            }
            return .partialSupported
        }()

        return RemoteSMILAnalysis(
            status: status,
            sourceSMILElementCount: smilElementTags,
            sourceCSSAnimationDetected: hasCSSAnimation,
            sourceJavaScriptDetected: hasJavaScript,
            parsedAnimationCount: parsedAnimationCount,
            unsupportedSmilElementKeys: unsupportedSmilElements,
            unsupportedSmilAttributeKeys: [],
            unsupportedOtherKeys: []
        )
    }

    private func detectSMILElementTags(from normalizedSource: String) -> Int {
        let candidates: [String] = [
            "<animate ",
            "<set ",
            "<animatetransform",
            "<animatemotion",
            "<animatecolor",
            "<animateTransform",
            "<animateMotion"
        ]
        return candidates.reduce(0) { total, token in
            let lowerToken = token.lowercased()
            return total + normalizedSource.components(separatedBy: lowerToken).count - 1
        }
    }

    private func detectSMILAnimations(from normalizedSource: String) -> Int {
        let tokens: [String] = [
            "<animate ",
            "<set ",
            "<animatetransform",
            "<animatemotion",
            "<animatecolor",
            "<animatetextpath"
        ]
        return tokens.reduce(0) { total, token in
            total + normalizedSource.components(separatedBy: token).count - 1
        }
    }

    private func detectUnsupportedSMILElements(from normalizedSource: String) -> [String] {
        let supportedTags: Set<String> = [
            "<animate",
            "<set",
            "<animatetransform",
            "<animatemotion",
            "<animatecolor"
        ]
        let allSmilTags: [String] = [
            "<animate",
            "<set",
            "<animatetransform",
            "<discrete",
            "<mpath",
            "<animatepath",
            "<animatetextpath"
        ]

        var unsupported: [String] = []
        for rawTag in allSmilTags {
            let tag = rawTag.lowercased()
            let hasTag = normalizedSource.contains(tag)
            if hasTag && !supportedTags.contains(tag) {
                unsupported.append(tag.trimmingCharacters(in: CharacterSet(charactersIn: "<")))
            }
        }
        return unsupported
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

    private func inlineExternalStylesheets(
        in sourceText: String,
        baseURL: URL
    ) async -> String {
        let stylesheetInfo = extractStylesheetLinkInfo(from: sourceText, baseURL: baseURL)
        if stylesheetInfo.matches.isEmpty {
            return sourceText
        }

        let inlineStyle = await loadAndMergeExternalStylesheets(from: stylesheetInfo.urls)
        if inlineStyle.isEmpty {
            return removeStylesheetLinkTags(from: sourceText, matches: stylesheetInfo.matches)
        }

        let mutableSource = NSMutableString(string: sourceText)
        for range in stylesheetInfo.matches.reversed() {
            mutableSource.replaceCharacters(in: range, with: "")
        }

        let styleBlock = "\n<style>\n\(inlineStyle)\n</style>\n"
        let closeRange = mutableSource.range(of: "</svg>", options: .caseInsensitive)
        if closeRange.location == NSNotFound {
            mutableSource.append(styleBlock)
        } else {
            mutableSource.insert(styleBlock, at: closeRange.location)
        }

        return String(mutableSource)
    }

    private func removeStylesheetLinkTags(
        from sourceText: String,
        matches: [NSRange]
    ) -> String {
        if matches.isEmpty {
            return sourceText
        }
        let mutableSource = NSMutableString(string: sourceText)
        for match in matches.reversed() {
            mutableSource.replaceCharacters(in: match, with: "")
        }
        return String(mutableSource)
    }

    private func loadAndMergeExternalStylesheets(
        from styleURLs: [URL]
    ) async -> String {
        var mergedStyles: String = ""
        for styleURL in styleURLs {
            guard let stylesheetText = await loadStylesheetPayload(from: styleURL) else {
                continue
            }
            if mergedStyles.isEmpty {
                mergedStyles = "/* \(styleURL.absoluteString) */\n" + stylesheetText
            } else {
                mergedStyles += "\n\n/* \(styleURL.absoluteString) */\n" + stylesheetText
            }
        }
        return mergedStyles
    }

    private func loadStylesheetPayload(from styleURL: URL) async -> String? {
        do {
            let (data, response) = try await loader.data(from: styleURL)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                return nil
            }
            let text = decodeSVGText(from: data).trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }

    private func extractStylesheetLinkInfo(
        from sourceText: String,
        baseURL: URL
    ) -> (matches: [NSRange], urls: [URL]) {
        let linkPattern = #"<link\b[^>]*>"#
        guard let linkRegex = try? NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive]) else {
            return ([], [])
        }

        let nsSource = sourceText as NSString
        let range = NSRange(location: 0, length: nsSource.length)
        let matches = linkRegex.matches(in: sourceText, options: [], range: range)

        var stylesheetRanges: [NSRange] = []
        var stylesheetURLs: [URL] = []
        var seen: Set<String> = []

        for match in matches {
            let matchedRange = match.range
            guard let tagRange = Range(matchedRange, in: sourceText) else {
                continue
            }
            let rawTag = String(sourceText[tagRange])
            guard let rawRel = attributeValue("rel", from: rawTag),
                  isStylesheetRelationship(rawRel) else {
                continue
            }
            guard let rawHref = attributeValue("href", from: rawTag)
                    ?? attributeValue("xlink:href", from: rawTag),
                  let stylesheetURL = resolveRemoteURL(rawHref, baseURL: baseURL) else {
                continue
            }
            let absoluteText = stylesheetURL.absoluteString
            if seen.insert(absoluteText).inserted {
                stylesheetURLs.append(stylesheetURL)
                stylesheetRanges.append(matchedRange)
            }
        }

        return (stylesheetRanges, stylesheetURLs)
    }

    private func isStylesheetRelationship(_ rawRelValue: String) -> Bool {
        let values = rawRelValue
            .split(whereSeparator: \.isWhitespace)
            .map { $0.lowercased() }
        return values.contains("stylesheet")
    }

    private func resolveRemoteURL(
        _ rawValue: String,
        baseURL: URL
    ) -> URL? {
        let sanitized = rawValue
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        guard let candidate = URL(string: sanitized, relativeTo: baseURL) else {
            return nil
        }
        return candidate.absoluteURL
    }

    private func attributeValue(_ name: String, from rawTag: String) -> String? {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let pattern = "(?i)\\b" + escapedName + "\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s\"'>/]+))"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let nsTag = rawTag as NSString
        let range = NSRange(location: 0, length: nsTag.length)
        guard let match = regex.firstMatch(in: rawTag, options: [], range: range) else {
            return nil
        }

        for groupIndex in 1...3 {
            if match.numberOfRanges > groupIndex {
                let valueRange = match.range(at: groupIndex)
                if valueRange.location != NSNotFound,
                   let value = Range(valueRange, in: rawTag) {
                    let rawValue = String(rawTag[value])
                    return rawValue
                }
            }
        }
        return nil
    }
}

private enum DemoCatalogMode: Int, CaseIterable {
    case all
    case animation
    case smil
    case w3c
    case remote

    var navigationTitle: String {
        switch self {
        case .all:
            return "SVGSwiftUI Demo"
        case .animation:
            return "애니메이션"
        case .smil:
            return "SMIL"
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
        case .smil:
            return "SMIL 샘플"
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
        case .smil:
            return "SMIL 샘플을 분리해 렌더 정합성과 타이밍 동작을 확인합니다. "
                + "지원: animate/set/animateTransform/animateMotion 기본 동작, keyTimes/keySplines/이벤트형 begin는 제한됩니다."
        case .w3c:
            return "단위 테스트 기반 W3C 시나리오 후보 샘플을 확인할 수 있습니다. "
                + "지원/미지원은 텍스트 코드와 unsupportedFeatures 힌트로 구분됩니다."
        case .remote:
            return "운영 URL로 SVG를 직접 받아 렌더링해 차이를 점검할 수 있습니다."
        }
    }
}

#Preview {
    ContentView()
}
