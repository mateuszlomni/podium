import SwiftUI

@main
struct PodiumApp: App {
    @StateObject private var player = PlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    player.handle(url: url)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                player.reconnect()
            case .background:
                player.disconnect()
            default:
                break
            }
        }
    }
}
