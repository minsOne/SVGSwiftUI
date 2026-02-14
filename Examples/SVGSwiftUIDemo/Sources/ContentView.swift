import SVGSwiftUI
import SwiftUI

struct ContentView: View {
    private let samples = DemoSamples.all

    @State private var selectedIndex = 0
    @State private var targetNodeID = DemoSamples.all.first?.defaultNodeID ?? ""
    @State private var fillEnabled = true
    @State private var strokeEnabled = false
    @State private var scale = 1.0
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var parseCache = SVGParseCache(maxCost: 4_000_000, maxEntries: 32)

    private var selectedSample: SampleSVG {
        samples[selectedIndex]
    }

    private var renderConfiguration: SVGRenderConfiguration {
        let targetNodeID = self.targetNodeID
        let fillEnabled = self.fillEnabled
        let strokeEnabled = self.strokeEnabled
        let scale = self.scale
        let offsetX = self.offsetX
        let offsetY = self.offsetY

        let mapOverride = NodeOverride(
            fill: fillEnabled ? .color(.init(red: 1, green: 0.25, blue: 0.25, alpha: 1)) : nil,
            scale: .init(width: scale, height: scale),
            offset: .init(x: offsetX, y: offsetY)
        )

        let resolver: NodeStyleResolver?
        if strokeEnabled {
            resolver = { context in
                guard context.id == targetNodeID || context.syntheticID == targetNodeID else {
                    return nil
                }
                return NodeOverride(
                    stroke: .color(.init(red: 0.05, green: 0.25, blue: 0.95, alpha: 1)),
                    strokeWidth: 3
                )
            }
        } else {
            resolver = nil
        }

        let overrides: NodeOverrideMap = targetNodeID.isEmpty ? [:] : [targetNodeID: mapOverride]
        return SVGRenderConfiguration(idOverrides: overrides, resolver: resolver)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sampleSelector
                    canvasSection
                    controlsSection
                }
                .padding(20)
            }
            .navigationTitle("SVGSwiftUI Demo")
        }
        .navigationViewStyle(.stack)
        .accessibilityIdentifier("demo.content")
        .onChange(of: selectedSample.id) { _ in
            targetNodeID = selectedSample.defaultNodeID
            scale = 1.0
            offsetX = 0
            offsetY = 0
        }
    }

    private var sampleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample")
                .font(.headline)
            Picker("Sample", selection: $selectedIndex) {
                ForEach(samples.indices, id: \.self) { index in
                    Text(samples[index].title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("demo.sampleList")
        }
    }

    private var canvasSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Canvas")
                .font(.headline)

            SVGView(
                source: .string(selectedSample.svg),
                cache: parseCache,
                configuration: renderConfiguration
            )
            .frame(height: 300)
            .background(Color(white: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("SVG Canvas")
            .accessibilityIdentifier("demo.canvas")

            Text("Target Node: \(targetNodeID)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(.headline)

            HStack {
                Text("Node ID")
                TextField("main-path", text: $targetNodeID)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Node ID Field")
                    .accessibilityIdentifier("demo.nodeIDField")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("demo.nodeIDRow")

            Toggle("Apply Fill Override (Map)", isOn: $fillEnabled)
                .accessibilityIdentifier("demo.fillToggle")
            Toggle("Apply Stroke Override (Resolver)", isOn: $strokeEnabled)
                .accessibilityIdentifier("demo.strokeToggle")

            VStack(alignment: .leading) {
                Text("Scale: \(scale, specifier: "%.2f")")
                Slider(value: $scale, in: 0.5...2.5, step: 0.1)
                    .accessibilityIdentifier("demo.scaleSlider")
            }

            VStack(alignment: .leading) {
                Text("Offset X: \(offsetX, specifier: "%.0f")")
                Slider(value: $offsetX, in: -60...60, step: 1)
                    .accessibilityIdentifier("demo.offsetXSlider")
            }

            VStack(alignment: .leading) {
                Text("Offset Y: \(offsetY, specifier: "%.0f")")
                Slider(value: $offsetY, in: -60...60, step: 1)
                    .accessibilityIdentifier("demo.offsetYSlider")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("demo.controls")
    }
}

#Preview {
    ContentView()
}
