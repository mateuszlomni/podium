import SwiftUI

enum ArtworkStyle: String {
    case coverFlow
    case vinyl
}

struct PodiumPlayerView: View {
    @EnvironmentObject private var player: PlayerViewModel
    @AppStorage("artworkStyle") private var artworkStyle = ArtworkStyle.coverFlow

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760
            let wheelSize = min(
                proxy.size.width - AppTheme.horizontalPadding * 2,
                proxy.size.height * 0.4,
                390
            )

            VStack(spacing: compact ? 12 : 18) {
                HeaderView(artworkStyle: $artworkStyle)

                artwork
                    .frame(maxHeight: .infinity)
                    .animation(.smooth(duration: 0.3), value: player.selectedAlbumIndex)

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
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 6)
            .padding(.bottom, compact ? 8 : 14)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        switch artworkStyle {
        case .coverFlow:
            CoverFlowView(
                albums: player.albums,
                selectedIndex: player.selectedAlbumIndex,
                playingIndex: player.playingAlbumIndex,
                isPlaying: player.isPlaying
            )
            .transition(.opacity)
        case .vinyl:
            let index = player.selectedAlbumIndex
            let album = player.albums.indices.contains(index) ? player.albums[index] : nil

            VinylView(
                album: album,
                isSpinning: player.isPlaying && index == player.playingAlbumIndex
            )
            .id(album?.id ?? "podium:empty")
            .transition(.opacity)
        }
    }
}

private struct HeaderView: View {
    @Binding var artworkStyle: ArtworkStyle

    var body: some View {
        HStack {
            Text("Podium")
                .font(.system(size: 24, weight: .light, design: .rounded))

            Spacer()

            Button {
                withAnimation(.smooth(duration: 0.35)) {
                    artworkStyle = artworkStyle == .coverFlow ? .vinyl : .coverFlow
                }
            } label: {
                Image(systemName: artworkStyle == .coverFlow ? "opticaldisc" : "square.stack")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(artworkStyle == .coverFlow ? "Show vinyl" : "Show covers")
        }
    }
}

private struct TrackInfoView: View {
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        VStack(spacing: 6) {
            switch player.connection {
            case .connected:
                Text(player.currentTrack?.title ?? "")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.8)
                Text(player.currentTrack?.artist ?? "")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.secondaryText)
            case .connecting:
                ProgressView()
                    .controlSize(.small)
            case .disconnected, .failed:
                Button(action: player.connect) {
                    HStack(spacing: 7) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text("Connect")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.spotify.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.spotify)

                if case .failed(let message) = player.connection {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
    }
}
