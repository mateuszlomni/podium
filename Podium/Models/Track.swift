import Foundation

struct Track: Identifiable, Equatable {
    let uri: String
    let title: String
    let artist: String
    let album: String
    let albumURI: String
    let artworkName: String?
    let duration: TimeInterval

    var id: String { uri }
}
