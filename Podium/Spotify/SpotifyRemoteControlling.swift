import Foundation
import UIKit

enum RemoteConnection: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

protocol SpotifyRemoteControlling: AnyObject {
    var connection: RemoteConnection { get }

    var onConnectionChange: ((RemoteConnection) -> Void)? { get set }
    /// Like App Remote's `playerStateDidChange`: fires on track, pause and seek
    /// changes only, not continuously while playing.
    var onStateChange: ((PlayerState) -> Void)? { get set }
    var onLibraryChange: (([AlbumCard]) -> Void)? { get set }
    /// Album art of the current track: nil while it loads or when the remote has none.
    var onArtworkChange: ((UIImage?) -> Void)? { get set }

    /// User-initiated: may switch to the Spotify app to authorize.
    func connect()
    /// Silent: only reconnects with an authorization obtained earlier.
    func reconnect()
    func disconnect()
    func handle(url: URL) -> Bool

    func play()
    func pause()
    func next()
    func previous()
    func seek(to seconds: TimeInterval)
    func play(uri: String)
}
