import SwiftUI

struct PodiumPlayerView: View {
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760
            let wheelSize = min(
                proxy.size.width - AppTheme.horizontalPadding * 2,
                proxy.size.height * 0.4,
                390
            )

            VStack(spacing: compact ? 12 : 16) {
                HeaderView()

                CoverFlowView(
                    albums: player.albums,
                    selectedIndex: player.selectedAlbumIndex,
                    playingIndex: player.playingAlbumIndex,
                    isPlaying: player.isPlaying
                )
                .frame(maxHeight: .infinity)

                TrackInfoView()

                ProgressViewBar()

                ClickWheelView(
                    isPlaying: player.isPlaying,
                    onMenu: player.menuPressed,
                    onPrevious: player.previousTrack,
                    onNext: player.nextTrack,
                    onPlayPause: player.togglePlayPause,
                    onSelect: player.selectPressed,
                    onRotationStep: player.wheelDidMove
                )
                .frame(width: wheelSize, height: wheelSize)

                if proxy.size.height >= 800 {
                    Text("A HIGHER WAY TO LISTEN")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(4)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, compact ? 8 : 14)
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Podium")
                    .font(.system(size: 30, weight: .light, design: .rounded))
                Text("FOR SPOTIFY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Text("MUSIC\nLIVES\nON")
                .font(.system(size: 10, weight: .medium))
                .tracking(4)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

private struct TrackInfoView: View {
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(spacing: 4) {
                Text(player.currentTrack?.title ?? "Not Playing")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity)

            ConnectionBadge(connection: player.connection, onConnect: player.connect)
        }
    }

    private var subtitle: String {
        if case .failed(let message) = player.connection {
            return message
        }
        return player.currentTrack?.artist ?? "Connect Spotify to start"
    }
}

private struct ConnectionBadge: View {
    let connection: RemoteConnection
    let onConnect: () -> Void

    var body: some View {
        switch connection {
        case .connected:
            label("Spotify")
                .foregroundStyle(AppTheme.spotify)
        case .connecting:
            HStack(spacing: 7) {
                ProgressView()
                    .controlSize(.small)
                Text("Connecting")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(AppTheme.secondaryText)
        case .disconnected, .failed:
            Button(action: onConnect) {
                label(connection == .disconnected ? "Connect" : "Retry")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.spotify.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.spotify)
        }
    }

    private func label(_ title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "dot.radiowaves.left.and.right")
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
    }
}
