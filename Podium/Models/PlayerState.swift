import Foundation

struct PlayerState: Equatable {
    let track: Track
    let isPaused: Bool
    let position: TimeInterval
    let contextURI: String?
}
