import Foundation

final class MockSpotifyRemote: SpotifyRemoteControlling {
    private(set) var connection: RemoteConnection = .disconnected

    var onConnectionChange: ((RemoteConnection) -> Void)?
    var onStateChange: ((PlayerState) -> Void)?
    var onLibraryChange: (([AlbumCard]) -> Void)?

    private var queue: [Track] = []
    private var index = 0
    private var isPaused = true
    private var anchorPosition: TimeInterval = 0
    private var anchorDate = Date()
    private var endOfTrackTask: Task<Void, Never>?

    private var currentTrack: Track? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    private var position: TimeInterval {
        isPaused ? anchorPosition : anchorPosition + Date().timeIntervalSince(anchorDate)
    }

    func connect() {
        guard connection != .connected else { return }
        connection = .connected
        onConnectionChange?(connection)
        onLibraryChange?(MockLibrary.albums)

        if queue.isEmpty {
            load(MockLibrary.tracks(inAlbum: "mock:album:horizons"), index: 0, from: 84, paused: false)
        } else {
            publish()
        }
    }

    func reconnect() {
        connect()
    }

    func disconnect() {
        guard connection == .connected else { return }
        endOfTrackTask?.cancel()
        connection = .disconnected
        onConnectionChange?(connection)
    }

    func handle(url: URL) -> Bool {
        false
    }

    func play() {
        setPaused(false)
    }

    func pause() {
        setPaused(true)
    }

    func next() {
        guard !queue.isEmpty else { return }
        load(queue, index: (index + 1) % queue.count, from: 0, paused: isPaused)
    }

    func previous() {
        guard !queue.isEmpty else { return }

        if position > 3 {
            seek(to: 0)
        } else {
            load(queue, index: (index - 1 + queue.count) % queue.count, from: 0, paused: isPaused)
        }
    }

    func seek(to seconds: TimeInterval) {
        guard let currentTrack else { return }
        anchorPosition = min(max(seconds, 0), currentTrack.duration)
        anchorDate = Date()
        publish()
    }

    func play(uri: String) {
        let tracks = MockLibrary.tracks(inAlbum: uri)
        guard !tracks.isEmpty else { return }
        load(tracks, index: 0, from: 0, paused: false)
    }

    private func setPaused(_ paused: Bool) {
        guard currentTrack != nil, paused != isPaused else { return }
        anchorPosition = position
        anchorDate = Date()
        isPaused = paused
        publish()
    }

    private func load(_ tracks: [Track], index: Int, from start: TimeInterval, paused: Bool) {
        queue = tracks
        self.index = index
        anchorPosition = start
        anchorDate = Date()
        isPaused = paused
        publish()
    }

    private func publish() {
        guard connection == .connected, let currentTrack else { return }
        scheduleEndOfTrack(currentTrack)
        onStateChange?(
            PlayerState(
                track: currentTrack,
                isPaused: isPaused,
                position: position,
                contextURI: currentTrack.albumURI
            )
        )
    }

    private func scheduleEndOfTrack(_ track: Track) {
        endOfTrackTask?.cancel()
        guard !isPaused else { return }

        let remaining = max(track.duration - position, 0)
        endOfTrackTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            self?.next()
        }
    }
}
