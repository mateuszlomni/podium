import SwiftUI
import UIKit
import WidgetKit

/// Mirrors what's playing into the app group so the widgets can show it.
@MainActor
final class NowPlayingPublisher {
    // WidgetKit refuses to render images above a pixel-area limit, so the shared artwork stays small.
    private let artworkSide: CGFloat = 256

    private var lastSnapshot: NowPlayingSnapshot?
    private var lastAlbumID: String?
    private var lastArtworkID: ObjectIdentifier?

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
        let artworkID = album?.artwork.map(ObjectIdentifier.init)
        let artworkChanged = album?.id != lastAlbumID || artworkID != lastArtworkID

        guard artworkChanged || hasChanged(snapshot) else { return }

        if artworkChanged {
            lastAlbumID = album?.id
            lastArtworkID = artworkID
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
        let size = CGSize(width: artworkSide, height: artworkSide)

        if let artwork = album.artwork {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                artwork.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        let renderer = ImageRenderer(content: LabelArt(album: album).frame(width: artworkSide, height: artworkSide))
        renderer.scale = 1
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
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
