import SwiftUI
import UIKit

struct AlbumCard: Identifiable {
    let uri: String
    let title: String
    let subtitle: String
    var symbol = "music.note.list"
    var gradient: [Color] = [Color(white: 0.18), Color(white: 0.06)]
    var artwork: UIImage?

    var id: String { uri }
}
