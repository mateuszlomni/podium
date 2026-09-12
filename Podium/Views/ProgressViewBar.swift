import SwiftUI

struct ProgressViewBar: View {
    @EnvironmentObject private var player: PlayerViewModel
    @State private var scrubFraction: Double?

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: !player.isPlaying || scrubFraction != nil)) { context in
            let duration = player.currentTrack?.duration ?? 0
            let progress = scrubFraction.map { $0 * duration } ?? player.progress(at: context.date)
            let value = duration > 0 ? progress / duration : 0

            VStack(spacing: 7) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.12))

                        Capsule()
                            .fill(.white.opacity(0.78))
                            .frame(width: proxy.size.width * value)

                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .offset(x: max(0, min(proxy.size.width - 12, proxy.size.width * value - 6)))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                scrubFraction = min(max(gesture.location.x / proxy.size.width, 0), 1)
                            }
                            .onEnded { _ in
                                if let scrubFraction {
                                    player.seek(to: scrubFraction)
                                }
                                self.scrubFraction = nil
                            }
                    )
                }
                .frame(height: 12)

                HStack {
                    Text(PlayerViewModel.timeString(progress))
                    Spacer()
                    Text("-" + PlayerViewModel.timeString(max(duration - progress, 0)))
                }
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
