import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            PodiumPlayerView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(PlayerViewModel())
}
