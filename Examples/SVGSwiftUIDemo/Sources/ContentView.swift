import Foundation
import SVGSwiftUI
import SwiftUI

struct ContentView: View {
    private let samples = DemoSamples.all

    @State private var expandedSources: Set<String> = []
    @State private var runningAnimations: Set<String> = {
        let animatedSamples = DemoSamples.all.filter { $0.animation.isAnimated }
        let animatedIDs = animatedSamples.map { $0.id }
        return Set<String>(animatedIDs)
    }()

    var body: some View {
        NavigationView {
            TimelineView(.animation) { timeline in
                let timestamp = timeline.date.timeIntervalSinceReferenceDate

                List {
                    sectionHeader
                    Section("SVG 샘플 목록") {
                        ForEach(samples) { sample in
                            sampleRow(for: sample, at: timestamp)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("SVGSwiftUI Demo")
                .accessibilityIdentifier("demo.content")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var sectionHeader: some View {
        Section {
            Text("List 방식으로 여러 SVG를 동시에 확인할 수 있습니다. 각 카드에서 코드 보기 버튼을 눌러 SVG 소스와 렌더 결과를 함께 확인하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 6)
        } header: {
            Text("Demo 가이드")
        }
    }

    private func sampleRow(for sample: SampleSVG, at timestamp: TimeInterval) -> some View {
        let configuration = renderConfiguration(for: sample, at: timestamp)
        let source = DemoSamples.source(for: sample)
        let sourceBinding = sourceExpandedBinding(for: sample.id)
        let animationBinding = animationEnabledBinding(for: sample.id)

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
                source: .string(source),
                configuration: configuration
            )
            .frame(height: 210)
            .background(Color(white: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .accessibilityLabel("\(sample.title) canvas")
            .accessibilityIdentifier("demo.canvas.\(sample.id)")

            if sample.animation != .none {
                Toggle(
                    "애니메이션 재생",
                    isOn: animationBinding
                )
                .font(.caption)
                .accessibilityIdentifier("demo.animationToggle.\(sample.id)")
            }

            DisclosureGroup(
                isExpanded: sourceBinding,
                content: {
                    Text(source)
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
        .accessibilityIdentifier("demo.sampleRow.\(sample.id)")
        .id(sample.id)
    }

    private func renderConfiguration(for sample: SampleSVG, at timestamp: TimeInterval) -> SVGRenderConfiguration {
        let isAnimationEnabled = runningAnimations.contains(sample.id)
        var overrides: NodeOverrideMap = [:]

        if isAnimationEnabled {
            switch sample.animation {
            case .none:
                break
            case let .pulse(nodeID: nodeID, minScale: minScale, maxScale: maxScale, duration: duration):
                let progress = animationProgress(for: timestamp, duration: duration)
                let scale = minScale + ((maxScale - minScale) * progress)
                overrides[nodeID] = NodeOverride(scale: .init(width: scale, height: scale))
            case let .drift(nodeID: nodeID, offsetX: offsetX, offsetY: offsetY, duration: duration):
                let progress = animationProgress(for: timestamp, duration: duration)
                let phaseOffset = (progress - 0.5) * 2.0
                let x = offsetX * phaseOffset
                let y = offsetY * phaseOffset
                overrides[nodeID] = NodeOverride(offset: .init(x: x, y: y))
            case let .opacity(nodeID: nodeID, minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration):
                let progress = animationProgress(for: timestamp, duration: duration)
                let alpha = minOpacity + ((maxOpacity - minOpacity) * progress)
                overrides[nodeID] = NodeOverride(opacity: alpha)
            }
        }

        return SVGRenderConfiguration(idOverrides: overrides)
    }

    private func animationProgress(for timestamp: TimeInterval, duration: Double) -> Double {
        let safeDuration = max(duration, 0.1)
        let normalized = timestamp.truncatingRemainder(dividingBy: safeDuration) / safeDuration
        let phase = normalized * 2.0 * Double.pi
        let sineValue = sin(phase)
        return (sineValue + 1.0) / 2.0
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
}

#Preview {
    ContentView()
}
