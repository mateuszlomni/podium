import SwiftUI
import WidgetKit

/// Mirrors what's playing into the app group so the widgets can show it.
@MainActor
final class NowPlayingPublisher {
    private var lastSnapshot: NowPlayingSnapshot?
    private var lastArtworkKey: String?

    func publish(track: Track?, isPlaying: Bool, position: TimeInterval, album: AlbumCard?) {
        guard let track else { return }

        let snapshot = NowPlayingSnapshot(
            title: track.title,
            artist: track.artist,
            isPlaying: isPlaying,
            position: position,
            duration: track.duration,
            updatedAt: .now
        )
        let artworkKey = "\(album?.id ?? "none"):\(album?.artwork != nil)"
        let artworkChanged = artworkKey != lastArtworkKey

        guard artworkChanged || hasChanged(snapshot) else { return }

        if artworkChanged {
            lastArtworkKey = artworkKey
            NowPlayingStore.saveArtwork(album.flatMap(labelImage(for:)))
        }
        lastSnapshot = snapshot
        NowPlayingStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: NowPlayingStore.widgetKind)
    }

    private func hasChanged(_ snapshot: NowPlayingSnapshot) -> Bool {
        guard let last = lastSnapshot else { return true }

        if last.title != snapshot.title || last.artist != snapshot.artist
            || last.isPlaying != snapshot.isPlaying || last.duration != snapshot.duration {
            return true
        }
        // Normal playback progress doesn't need a reload; only seeks move the timeline.
        let drift = snapshot.isPlaying
            ? abs(last.startDate.timeIntervalSince(snapshot.startDate))
            : abs(last.position - snapshot.position)
        return drift > 2
    }

    private func labelImage(for album: AlbumCard) -> UIImage? {
        if let artwork = album.artwork {
            return artwork
        }
        let renderer = ImageRenderer(content: LabelArt(album: album))
        renderer.scale = 2
        return renderer.uiImage
    }
}

private struct LabelArt: View {
    let album: AlbumCard

    var body: some View {
        ZStack {
            LinearGradient(
                colors: album.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: album.symbol)
                .font(.system(size: 70, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 240, height: 240)
    }
}
