import SwiftUI

struct ProgressViewBar: View {
    @EnvironmentObject private var player: PlayerViewModel
    @State private var scrubFraction: Double?

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: !player.isPlaying || scrubFraction != nil)) { context in
            let duration = player.currentTrack?.duration ?? 0
            let progress = scrubFraction.map { $0 * duration } ?? player.progress(at: context.date)
            let value = duration > 0 ? progress / duration : 0

            VStack(spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 3)

                        Capsule()
                            .fill(.white.opacity(0.7))
                            .frame(width: proxy.size.width * value, height: 3)

                        Circle()
                            .fill(.white)
                            .frame(width: 11, height: 11)
                            .offset(x: max(0, min(proxy.size.width - 11, proxy.size.width * value - 5.5)))
                            .opacity(scrubFraction == nil ? 0 : 1)
                            .animation(.easeOut(duration: 0.15), value: scrubFraction == nil)
                    }
                    .frame(maxHeight: .infinity)
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
                .frame(height: 20)

                HStack {
                    Text(PlayerViewModel.timeString(progress))
                    Spacer()
                    Text("-" + PlayerViewModel.timeString(max(duration - progress, 0)))
                }
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
