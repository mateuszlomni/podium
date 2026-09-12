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
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.055),
                                Color.white.opacity(0.018),
                                Color.black.opacity(0.65)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: size / 2
                        )
                    )

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.accent.opacity(0.95),
                                .white.opacity(0.2),
                                AppTheme.accent.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
                    .shadow(color: AppTheme.accent.opacity(0.28), radius: 12)

                Button("MENU", action: onMenu)
                    .buttonStyle(.plain)
                    .font(.system(size: 19, weight: .medium))
                    .offset(y: -size * 0.37)

                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 28, weight: .semibold))
                }
                .buttonStyle(.plain)
                .offset(x: -size * 0.37)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 28, weight: .semibold))
                }
                .buttonStyle(.plain)
                .offset(x: size * 0.37)

                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                }
                .buttonStyle(.plain)
                .offset(y: size * 0.37)

                Button(action: onSelect) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.09), .black.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .frame(width: size * 0.34, height: size * 0.34)
            }
            .frame(width: size, height: size)
            .foregroundStyle(.white.opacity(0.92))
            .contentShape(Circle())
            .gesture(wheelGesture(in: size))
        }
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
