import Foundation
import UIKit

nonisolated struct NowPlayingSnapshot: Codable, Equatable {
    var title: String
    var artist: String
    var isPlaying: Bool
    var position: TimeInterval
    var duration: TimeInterval
    var updatedAt: Date

    var startDate: Date {
        updatedAt.addingTimeInterval(-position)
    }

    var endDate: Date {
        startDate.addingTimeInterval(duration)
    }
}

/// Shared between the app and the widgets through the app group container.
nonisolated enum NowPlayingStore {
    static let widgetKind = "NowPlaying"

    private static var containerURL: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "PodiumAppGroup") as? String,
              !group.isEmpty else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    }

    private static var snapshotURL: URL? {
        containerURL?.appendingPathComponent("now-playing.json")
    }

    private static var artworkURL: URL? {
        containerURL?.appendingPathComponent("now-playing-artwork.png")
    }

    static func load() -> NowPlayingSnapshot? {
        guard let snapshotURL, let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? JSONDecoder().decode(NowPlayingSnapshot.self, from: data)
    }

    static func save(_ snapshot: NowPlayingSnapshot) {
        guard let snapshotURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: snapshotURL, options: .atomic)
    }

    static func loadArtwork() -> UIImage? {
        guard let artworkURL else { return nil }
        return UIImage(contentsOfFile: artworkURL.path)
    }

    static func saveArtwork(_ image: UIImage?) {
        guard let artworkURL else { return }

        if let data = image?.pngData() {
            try? data.write(to: artworkURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: artworkURL)
        }
    }
}
