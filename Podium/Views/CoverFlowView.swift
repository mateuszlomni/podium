import SwiftUI

struct CoverFlowView: View {
    let albums: [AlbumCard]
    let selectedIndex: Int
    let playingIndex: Int?
    let isPlaying: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.height, proxy.size.width * 0.62)
            let cards = albums.isEmpty ? [AlbumCard.placeholder] : albums

            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, album in
                    let offset = CGFloat(index - selectedIndex)
                    AlbumArtworkCard(
                        album: album,
                        isNowPlaying: index == playingIndex,
                        isPlaying: isPlaying
                    )
                    .frame(width: side, height: side)
                    .scaleEffect(index == selectedIndex ? 1 : 0.82)
                    .rotation3DEffect(
                        .degrees(Double(offset) * -12),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.7
                    )
                    .offset(x: offset * side * 0.55)
                    .zIndex(-Double(abs(offset)))
                    .opacity(abs(offset) > 1.5 ? 0 : 1)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: selectedIndex)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension AlbumCard {
    static let placeholder = AlbumCard(
        uri: "podium:placeholder",
        title: "Podium",
        subtitle: "",
        symbol: "hifispeaker.fill"
    )
}

private struct AlbumArtworkCard: View {
    let album: AlbumCard
    let isNowPlaying: Bool
    let isPlaying: Bool

    var body: some View {
        ZStack {
            if let artwork = album.artwork {
                Color.clear
                    .overlay {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                    }
            } else {
                LinearGradient(
                    colors: album.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: album.symbol)
                    .font(.system(size: 56, weight: .thin))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isNowPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .semibold))
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(7)
                    .background(.black.opacity(0.3), in: Circle())
                    .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.4), radius: 24, y: 14)
    }
}
