import Foundation

enum SpotifyConfiguration {
    /// Comes from SPOTIFY_CLIENT_ID in Config/Secrets.xcconfig (see Secrets.example.xcconfig).
    static let clientID = Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String ?? ""
    /// Must be listed under Redirect URIs in the dashboard and match the URL scheme in Info.plist.
    static let redirectURL = URL(string: "podium-player://spotify-login-callback")!

    static var isConfigured: Bool {
        !clientID.isEmpty
    }
}
