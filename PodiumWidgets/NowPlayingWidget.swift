import SwiftUI
import WidgetKit

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let snapshot: NowPlayingSnapshot?
    let artwork: UIImage?
}

struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(date: .now, snapshot: .preview, artwork: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        // The app reloads the timeline whenever the track, pause state or position changes.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> NowPlayingEntry {
        NowPlayingEntry(date: .now, snapshot: NowPlayingStore.load(), artwork: NowPlayingStore.loadArtwork())
    }
}

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NowPlayingStore.widgetKind, provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.025, green: 0.03, blue: 0.04)
                }
        }
        .configurationDisplayName("Now Playing")
        .description("The record Podium is playing.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

private extension NowPlayingSnapshot {
    static let preview = NowPlayingSnapshot(
        title: "Night Drive",
        artist: "Nova Echo",
        isPlaying: true,
        position: 84,
        duration: 237,
        updatedAt: .now
    )
}
