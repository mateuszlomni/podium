import Foundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var connection: RemoteConnection = .disconnected
    @Published private(set) var albums: [AlbumCard] = []
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var selectedAlbumIndex = 0
    @Published private var positionAnchor = PositionAnchor(position: 0, date: .now)

    private let remote: SpotifyRemoteControlling
    private let nowPlaying = NowPlayingPublisher()
    private var contextURI: String?

    init(remote: SpotifyRemoteControlling) {
        self.remote = remote

        remote.onConnectionChange = { [weak self] connection in
            self?.connection = connection
        }
        remote.onLibraryChange = { [weak self] albums in
            self?.update(albums)
        }
        remote.onStateChange = { [weak self] state in
            self?.apply(state)
        }
        remote.reconnect()
    }

    convenience init() {
        self.init(remote: Self.makeRemote())
    }

    var isConnected: Bool {
        connection == .connected
    }

    var playingAlbumIndex: Int? {
        albums.firstIndex { $0.uri == contextURI }
            ?? albums.firstIndex { $0.uri == currentTrack?.albumURI }
    }

    func progress(at date: Date) -> TimeInterval {
        guard let currentTrack else { return 0 }
        let elapsed = isPlaying ? date.timeIntervalSince(positionAnchor.date) : 0
        return min(max(positionAnchor.position + elapsed, 0), currentTrack.duration)
    }

    func connect() {
        remote.connect()
    }

    func reconnect() {
        remote.reconnect()
    }

    func disconnect() {
        remote.disconnect()
    }

    func handle(url: URL) {
        _ = remote.handle(url: url)
    }

    func togglePlayPause() {
        guard isConnected else {
            connect()
            return
        }
        guard currentTrack != nil else { return }
        setPosition(progress(at: .now))
        isPlaying.toggle()
        isPlaying ? remote.play() : remote.pause()
        publishNowPlaying()
    }

    func nextTrack() {
        guard isConnected else { return }
        remote.next()
    }

    func previousTrack() {
        guard isConnected else { return }
        remote.previous()
    }

    func seek(to fraction: Double) {
        guard isConnected, let currentTrack else { return }
        setPosition(currentTrack.duration * min(max(fraction, 0), 1))
        remote.seek(to: positionAnchor.position)
        publishNowPlaying()
    }

    func wheelDidMove(steps: Int) {
        guard !albums.isEmpty else { return }
        selectedAlbumIndex = min(max(selectedAlbumIndex + steps, 0), albums.count - 1)
    }

    func selectPressed() {
        guard isConnected else {
            connect()
            return
        }
        guard albums.indices.contains(selectedAlbumIndex) else { return }

        if selectedAlbumIndex == playingAlbumIndex {
            togglePlayPause()
        } else {
            remote.play(uri: albums[selectedAlbumIndex].uri)
        }
    }

    func menuPressed() {
        if let playingAlbumIndex {
            selectedAlbumIndex = playingAlbumIndex
        }
    }

    static func timeString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // The Spotify app can't run in the Simulator, so the mock is the default there.
    // Launch with `-PodiumRemote spotify` or `-PodiumRemote mock` to override.
    private static func makeRemote() -> SpotifyRemoteControlling {
        #if canImport(SpotifyiOS)
        #if targetEnvironment(simulator)
        let prefersSpotify = UserDefaults.standard.string(forKey: "PodiumRemote") == "spotify"
        #else
        let prefersSpotify = UserDefaults.standard.string(forKey: "PodiumRemote") != "mock"
        #endif

        if prefersSpotify, SpotifyConfiguration.isConfigured {
            return SpotifyRemoteManager(
                clientID: SpotifyConfiguration.clientID,
                redirectURL: SpotifyConfiguration.redirectURL
            )
        }
        #endif
        return MockSpotifyRemote()
    }

    private func update(_ newAlbums: [AlbumCard]) {
        let hadAlbums = !albums.isEmpty
        albums = newAlbums

        if !hadAlbums, let playingAlbumIndex {
            selectedAlbumIndex = playingAlbumIndex
        } else {
            selectedAlbumIndex = min(selectedAlbumIndex, max(albums.count - 1, 0))
        }
        publishNowPlaying()
    }

    private func apply(_ state: PlayerState) {
        let previousPlayingIndex = playingAlbumIndex

        currentTrack = state.track
        contextURI = state.contextURI
        isPlaying = !state.isPaused
        setPosition(state.position)

        if let playingAlbumIndex, playingAlbumIndex != previousPlayingIndex {
            selectedAlbumIndex = playingAlbumIndex
        }
        publishNowPlaying()
    }

    private func setPosition(_ position: TimeInterval) {
        positionAnchor = PositionAnchor(position: position, date: .now)
    }

    private func publishNowPlaying() {
        nowPlaying.publish(
            track: currentTrack,
            isPlaying: isPlaying,
            position: progress(at: .now),
            album: playingAlbumIndex.map { albums[$0] }
        )
    }
}

private struct PositionAnchor {
    let position: TimeInterval
    let date: Date
}
