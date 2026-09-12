import SwiftUI

enum MockLibrary {
    static let albums: [AlbumCard] = [
        AlbumCard(
            uri: "mock:album:after-hours",
            title: "After Hours",
            subtitle: "Lumen",
            symbol: "moon.stars.fill",
            gradient: [.black, .gray]
        ),
        AlbumCard(
            uri: "mock:album:horizons",
            title: "Horizons",
            subtitle: "Nova Echo",
            symbol: "car.rear.waves.up.fill",
            gradient: [
                Color(red: 0.02, green: 0.09, blue: 0.16),
                Color(red: 0.07, green: 0.23, blue: 0.38)
            ]
        ),
        AlbumCard(
            uri: "mock:album:still-here",
            title: "Still Here",
            subtitle: "Aeris",
            symbol: "water.waves",
            gradient: [
                Color(red: 0.35, green: 0.40, blue: 0.48),
                Color(red: 0.08, green: 0.10, blue: 0.14)
            ]
        )
    ]

    private static let songs: [String: [(title: String, duration: TimeInterval)]] = [
        "mock:album:after-hours": [
            ("Midnight Signal", 228), ("Neon Rain", 245), ("Quiet Streets", 201), ("Last Train Home", 272)
        ],
        "mock:album:horizons": [
            ("Night Drive", 237), ("Coastline", 214), ("Afterglow", 251), ("Open Road", 223)
        ],
        "mock:album:still-here": [
            ("Low Tide", 209), ("Glass Water", 258), ("Still Here", 232), ("Undertow", 302)
        ]
    ]

    static func tracks(inAlbum uri: String) -> [Track] {
        guard let album = albums.first(where: { $0.uri == uri }) else { return [] }

        return (songs[uri] ?? []).enumerated().map { index, song in
            Track(
                uri: "\(uri):track:\(index + 1)",
                title: song.title,
                artist: album.subtitle,
                album: album.title,
                albumURI: uri,
                artworkName: nil,
                duration: song.duration
            )
        }
    }
}
