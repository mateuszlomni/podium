import SwiftUI
import UIKit

enum ArtworkStyle: String {
    case coverFlow
    case vinyl
}

struct PodiumPlayerView: View {
    @AppStorage("artworkStyle") private var artworkStyle = ArtworkStyle.coverFlow

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(artworkStyle: $artworkStyle)
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 6)

            ZStack {
                switch artworkStyle {
                case .coverFlow:
                    WheelLayout()
                        .transition(.opacity)
                case .vinyl:
                    VinylLayout()
                        .transition(.opacity)
                }
            }
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

private struct WheelLayout: View {
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 710
            let wheelSize = min(
                proxy.size.width - AppTheme.horizontalPadding * 2,
                proxy.size.height * 0.43,
                390
            )

            VStack(spacing: compact ? 12 : 18) {
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
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, compact ? 6 : 12)
            .padding(.bottom, compact ? 8 : 14)
        }
    }
}

private struct VinylLayout: View {
    @EnvironmentObject private var player: PlayerViewModel
    @State private var swipeOffset: CGFloat = 0
    @State private var feedbackSymbol: String?

    private var nowPlayingAlbum: AlbumCard? {
        player.nowPlayingCard
    }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width * 1.3, proxy.size.height - 160)

            VStack(spacing: 20) {
                // The record is wider than the screen; the clear base keeps it from widening the layout.
                Color.clear
                    .overlay {
                        record
                            .frame(width: diameter, height: diameter)
                    }

                VStack(spacing: 14) {
                    TrackInfoView()
                    ProgressViewBar()
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.bottom, 14)
            }
        }
    }

    private var record: some View {
        interactiveRecord
            .accessibilityElement()
            .accessibilityLabel(Text("Record"))
            .accessibilityHint(Text("Tap to play or pause, swipe to change track"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { togglePlayback() }
            .accessibilityAction(named: Text("Next track")) { skipForward() }
            .accessibilityAction(named: Text("Previous track")) { skipBackward() }
    }

    private var interactiveRecord: some View {
        spinningRecord
            .offset(x: swipeOffset)
            .contentShape(Circle())
            .onTapGesture { togglePlayback() }
            .gesture(swipeGesture)
    }

    private var spinningRecord: some View {
        VinylView(album: nowPlayingAlbum, isSpinning: player.isPlaying)
            .id(nowPlayingAlbum?.id ?? "podium:empty")
            .overlay { feedbackBadge }
            .animation(.smooth(duration: 0.4), value: nowPlayingAlbum?.id)
    }

    @ViewBuilder
    private var feedbackBadge: some View {
        if let feedbackSymbol {
            Image(systemName: feedbackSymbol)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 80, height: 80)
                .background(.black.opacity(0.45), in: Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                swipeOffset = value.translation.width / 4
            }
            .onEnded { value in
                let dx = value.translation.width

                if abs(dx) > 60, abs(dx) > abs(value.translation.height) {
                    if dx < 0 {
                        skipForward()
                    } else {
                        skipBackward()
                    }
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    swipeOffset = 0
                }
            }
    }

    private func togglePlayback() {
        guard player.isConnected else {
            player.connect()
            return
        }
        player.togglePlayPause()
        showFeedback(player.isPlaying ? "play.fill" : "pause.fill")
    }

    private func skipForward() {
        guard player.isConnected else { return }
        player.nextTrack()
        showFeedback("forward.fill")
    }

    private func skipBackward() {
        guard player.isConnected else { return }
        player.previousTrack()
        showFeedback("backward.fill")
    }

    private func showFeedback(_ symbol: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.15)) {
            feedbackSymbol = symbol
        }
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            withAnimation(.easeIn(duration: 0.25)) {
                if feedbackSymbol == symbol {
                    feedbackSymbol = nil
                }
            }
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
