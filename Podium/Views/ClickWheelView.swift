import SwiftUI
import UIKit

struct ClickWheelView: View {
    let isPlaying: Bool
    let onMenu: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPlayPause: () -> Void
    let onSelect: () -> Void
    let onRotationStep: (Int) -> Void

    @State private var previousAngle: Double?
    @State private var accumulatedAngle: Double = 0

    private let stepAngle = 12.0

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.035))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }

                wheelButton("line.3.horizontal", label: "Menu", action: onMenu)
                    .offset(y: -size * 0.37)

                wheelButton("backward.end.fill", label: "Previous", action: onPrevious)
                    .offset(x: -size * 0.37)

                wheelButton("forward.end.fill", label: "Next", action: onNext)
                    .offset(x: size * 0.37)

                wheelButton(isPlaying ? "pause.fill" : "play.fill", label: isPlaying ? "Pause" : "Play", action: onPlayPause)
                    .offset(y: size * 0.37)

                Button(action: onSelect) {
                    Circle()
                        .fill(.white.opacity(0.05))
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .frame(width: size * 0.34, height: size * 0.34)
                .accessibilityLabel("Select")
            }
            .frame(width: size, height: size)
            .foregroundStyle(.white.opacity(0.75))
            .contentShape(Circle())
            .gesture(wheelGesture(in: size))
        }
    }

    private func wheelButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .regular))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func wheelGesture(in size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: size / 2, y: size / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y

                let radius = hypot(dx, dy)
                let innerRadius = size * 0.19

                guard radius > innerRadius else {
                    previousAngle = nil
                    accumulatedAngle = 0
                    return
                }

                let angle = atan2(dy, dx) * 180 / .pi

                guard let old = previousAngle else {
                    previousAngle = angle
                    return
                }

                var delta = angle - old

                if delta > 180 { delta -= 360 }
                if delta < -180 { delta += 360 }

                accumulatedAngle += delta
                previousAngle = angle

                if abs(accumulatedAngle) >= stepAngle {
                    let steps = Int(accumulatedAngle / stepAngle)
                    accumulatedAngle -= Double(steps) * stepAngle

                    UISelectionFeedbackGenerator().selectionChanged()
                    onRotationStep(steps)
                }
            }
            .onEnded { _ in
                previousAngle = nil
                accumulatedAngle = 0
            }
    }
}
