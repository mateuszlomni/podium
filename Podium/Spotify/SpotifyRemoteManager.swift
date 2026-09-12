#if canImport(SpotifyiOS)
import Foundation
import SpotifyiOS
import UIKit

final class SpotifyRemoteManager: NSObject, SpotifyRemoteControlling {
    private enum Attempt {
        case silent
        case userInitiated
        case authorized
    }

    private(set) var connection: RemoteConnection = .disconnected {
        didSet {
            if connection != oldValue {
                onConnectionChange?(connection)
            }
        }
    }

    var onConnectionChange: ((RemoteConnection) -> Void)?
    var onStateChange: ((PlayerState) -> Void)?
    var onLibraryChange: (([AlbumCard]) -> Void)?

    private let appRemote: SPTAppRemote
    private var attempt = Attempt.silent
    private var recommended: [AlbumCard] = []
    private var nowPlayingCard: AlbumCard?

    init(clientID: String, redirectURL: URL) {
        appRemote = SPTAppRemote(
            configuration: SPTConfiguration(clientID: clientID, redirectURL: redirectURL),
            logLevel: .error
        )
        super.init()
        appRemote.delegate = self
    }

    func connect() {
        guard connection != .connected, connection != .connecting else { return }
        connection = .connecting

        if appRemote.connectionParameters.accessToken == nil {
            authorize()
        } else {
            attempt = .userInitiated
            appRemote.connect()
        }
    }

    func reconnect() {
        // Leaves a failure on screen until the user retries.
        guard connection == .disconnected, appRemote.connectionParameters.accessToken != nil else { return }
        connection = .connecting
        attempt = .silent
        appRemote.connect()
    }

    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
        connection = .disconnected
    }

    func handle(url: URL) -> Bool {
        guard let parameters = appRemote.authorizationParameters(from: url) else { return false }

        if let accessToken = parameters[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = accessToken
            connection = .connecting
            attempt = .authorized
            appRemote.connect()
        } else {
            connection = .failed(parameters[SPTAppRemoteErrorDescriptionKey] ?? "Spotify authorization failed")
        }
        return true
    }

    func play() {
        appRemote.playerAPI?.resume(nil)
    }

    func pause() {
        appRemote.playerAPI?.pause(nil)
    }

    func next() {
        appRemote.playerAPI?.skip(toNext: nil)
    }

    func previous() {
        appRemote.playerAPI?.skip(toPrevious: nil)
    }

    func seek(to seconds: TimeInterval) {
        appRemote.playerAPI?.seek(toPosition: Int(seconds * 1000), callback: nil)
    }

    func play(uri: String) {
        appRemote.playerAPI?.play(uri, callback: nil)
    }

    /// Switches to Spotify for a token. This also wakes Spotify if it was suspended,
    /// and resumes the last played song.
    private func authorize() {
        appRemote.authorizeAndPlayURI("") { [weak self] spotifyInstalled in
            if !spotifyInstalled {
                self?.connection = .failed("Install the Spotify app to connect")
            }
        }
    }

    private func didConnect() {
        connection = .connected
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] result, _ in
            if let state = result as? SPTAppRemotePlayerState {
                self?.apply(state)
            }
        })
        loadRecommendedContent()
    }

    private func didFailToConnect(_ error: Error?) {
        switch attempt {
        case .userInitiated:
            // The token may have expired or Spotify may be suspended; authorizing fixes both.
            authorize()
        case .silent:
            connection = .disconnected
        case .authorized:
            connection = .failed(error?.localizedDescription ?? "Couldn't connect to Spotify")
        }
    }

    private func apply(_ state: SPTAppRemotePlayerState) {
        updateNowPlayingCard(for: state)
        onStateChange?(PlayerState(state))
    }

    private func loadRecommendedContent() {
        appRemote.contentAPI?.fetchRecommendedContentItems(
            forType: SPTAppRemoteContentTypeDefault,
            flattenContainers: true
        ) { [weak self] result, _ in
            guard let self, let items = result as? [SPTAppRemoteContentItem] else { return }

            let playable = Array(items.filter(\.isPlayable).prefix(12))
            recommended = playable.map { AlbumCard(uri: $0.uri, title: $0.title ?? "", subtitle: $0.subtitle ?? "") }
            publishLibrary()
            for item in playable {
                fetchArtwork(for: item, cardURI: item.uri)
            }
        }
    }

    private func updateNowPlayingCard(for state: SPTAppRemotePlayerState) {
        let album = state.track.album
        let knownURIs = Set(recommended.map(\.uri))

        guard !knownURIs.contains(state.contextURI.absoluteString), !knownURIs.contains(album.uri) else {
            if nowPlayingCard != nil {
                nowPlayingCard = nil
                publishLibrary()
            }
            return
        }
        guard nowPlayingCard?.uri != album.uri else { return }

        nowPlayingCard = AlbumCard(uri: album.uri, title: album.name, subtitle: state.track.artist.name)
        publishLibrary()
        fetchArtwork(for: state.track, cardURI: album.uri)
    }

    private func publishLibrary() {
        onLibraryChange?(recommended + [nowPlayingCard].compactMap { $0 })
    }

    private func fetchArtwork(for item: SPTAppRemoteImageRepresentable, cardURI: String) {
        appRemote.imageAPI?.fetchImage(forItem: item, with: CGSize(width: 600, height: 600)) { [weak self] result, _ in
            guard let self, let image = result as? UIImage else { return }

            if let index = recommended.firstIndex(where: { $0.uri == cardURI }) {
                recommended[index].artwork = image
            } else if nowPlayingCard?.uri == cardURI {
                nowPlayingCard?.artwork = image
            } else {
                return
            }
            publishLibrary()
        }
    }
}

// SpotifyiOS calls back on the main thread (see "Is SpotifyiOS.framework thread safe?" in its README).
extension SpotifyRemoteManager: SPTAppRemoteDelegate {
    nonisolated func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        MainActor.assumeIsolated {
            didConnect()
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        MainActor.assumeIsolated {
            didFailToConnect(error)
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        MainActor.assumeIsolated {
            connection = .disconnected
        }
    }
}

extension SpotifyRemoteManager: SPTAppRemotePlayerStateDelegate {
    nonisolated func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        MainActor.assumeIsolated {
            apply(playerState)
        }
    }
}

private extension PlayerState {
    init(_ state: SPTAppRemotePlayerState) {
        let track = state.track

        self.init(
            track: Track(
                uri: track.uri,
                title: track.name,
                artist: track.artist.name,
                album: track.album.name,
                albumURI: track.album.uri,
                artworkName: nil,
                duration: TimeInterval(track.duration) / 1000
            ),
            isPaused: state.isPaused,
            position: TimeInterval(state.playbackPosition) / 1000,
            contextURI: state.contextURI.absoluteString
        )
    }
}
#endif
