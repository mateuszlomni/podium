import SwiftUI
import WidgetKit

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NowPlayingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumNowPlayingView(entry: entry)
        case .accessoryCircular:
            CircularNowPlayingView(entry: entry)
        case .accessoryRectangular:
            RectangularNowPlayingView(entry: entry)
        case .accessoryInline:
            InlineNowPlayingView(entry: entry)
        default:
            SmallNowPlayingView(entry: entry)
        }
    }
}

private struct SmallNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        WidgetRecord(artwork: entry.artwork)
            .scaleEffect(1.2)
            .overlay(alignment: .bottomTrailing) {
                if entry.snapshot?.isPlaying == true {
                    Image(systemName: "waveform")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(12)
                }
            }
    }
}

private struct MediumNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height

            ZStack(alignment: .leading) {
                WidgetRecord(artwork: entry.artwork)
                    .frame(width: height * 1.2, height: height * 1.2)
                    .position(x: height * 0.3, y: height / 2)

                VStack(alignment: .leading, spacing: 4) {
                    Spacer(minLength: 0)

                    Text(entry.snapshot?.title ?? "Not Playing")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(entry.snapshot?.artist ?? "Open Podium to connect")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer(minLength: 0)

                    if let snapshot = entry.snapshot {
                        TrackProgress(snapshot: snapshot, now: entry.date)
                            .tint(.white.opacity(0.85))
                    }
                }
                .lineLimit(1)
                .padding(.leading, height)
                .padding(.trailing, 18)
                .padding(.vertical, 18)
            }
        }
    }
}

private struct CircularNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        if let snapshot = entry.snapshot, snapshot.isPlaying, snapshot.duration > 0, snapshot.endDate > entry.date {
            ProgressView(timerInterval: snapshot.startDate...snapshot.endDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 16, weight: .light))
            }
            .progressViewStyle(.circular)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "opticaldisc")
                    .font(.system(size: 22, weight: .light))
            }
        }
    }
}

private struct RectangularNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.snapshot?.title ?? "Podium")
                .font(.headline)
                .widgetAccentable()
            Text(entry.snapshot?.artist ?? "Not playing")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let snapshot = entry.snapshot {
                TrackProgress(snapshot: snapshot, now: entry.date)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InlineNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            Label("\(snapshot.title) · \(snapshot.artist)", systemImage: "opticaldisc")
        } else {
            Label("Podium", systemImage: "opticaldisc")
        }
    }
}

/// Advances on its own while playing, so the widget doesn't need timeline reloads for progress.
private struct TrackProgress: View {
    let snapshot: NowPlayingSnapshot
    let now: Date

    var body: some View {
        if snapshot.isPlaying, snapshot.duration > 0, snapshot.endDate > now {
            ProgressView(timerInterval: snapshot.startDate...snapshot.endDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        } else {
            ProgressView(value: snapshot.duration > 0 ? min(snapshot.position / snapshot.duration, 1) : 0)
        }
    }
}

private struct WidgetRecord: View {
    let artwork: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .fill(Color(white: 0.06))

                ForEach(0..<14, id: \.self) { groove in
                    Circle()
                        .stroke(.white.opacity(groove.isMultiple(of: 4) ? 0.08 : 0.035), lineWidth: 0.75)
                        .padding(side * (0.05 + CGFloat(groove) * 0.022))
                }

                label
                    .frame(width: side * 0.36, height: side * 0.36)
                    .clipShape(Circle())

                Circle()
                    .fill(.black)
                    .frame(width: side * 0.03, height: side * 0.03)
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    @ViewBuilder
    private var label: some View {
        if let artwork {
            Image(uiImage: artwork)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [Color(white: 0.24), Color(white: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
