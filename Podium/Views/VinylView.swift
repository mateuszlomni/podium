import SwiftUI

struct VinylView: View {
    let album: AlbumCard?
    let isSpinning: Bool

    @State private var restingAngle: Double = 0
    @State private var spinStart: Date?

    // 33⅓ rpm.
    private let degreesPerSecond = 360 / 1.8

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            TimelineView(.animation(minimumInterval: nil, paused: !isSpinning)) { context in
                Record(album: album, side: side)
                    .rotationEffect(.degrees(angle(at: context.date)))
            }
            .overlay {
                // The reflection stays put while the record turns underneath it.
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [.clear, .white.opacity(0.07), .clear, .clear, .white.opacity(0.05), .clear],
                            center: .center,
                            angle: .degrees(-30)
                        )
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .shadow(color: .black.opacity(0.55), radius: 26, y: 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if isSpinning {
                spinStart = .now
            }
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                spinStart = .now
            } else {
                restingAngle = angle(at: .now)
                spinStart = nil
            }
        }
    }

    private func angle(at date: Date) -> Double {
        guard let spinStart else { return restingAngle }
        return restingAngle + date.timeIntervalSince(spinStart) * degreesPerSecond
    }
}

private struct Record: View {
    let album: AlbumCard?
    let side: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.05))

            ForEach(0..<26, id: \.self) { groove in
                Circle()
                    .stroke(.white.opacity(groove.isMultiple(of: 5) ? 0.07 : 0.03), lineWidth: 1)
                    .padding(side * (0.05 + CGFloat(groove) * 0.012))
            }

            RecordLabel(album: album)
                .frame(width: side * 0.34, height: side * 0.34)
                .clipShape(Circle())

            Circle()
                .fill(AppTheme.background)
                .frame(width: side * 0.022, height: side * 0.022)
        }
        .frame(width: side, height: side)
        .drawingGroup()
    }
}

private struct RecordLabel: View {
    let album: AlbumCard?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let artwork = album?.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                } else if let album {
                    LinearGradient(
                        colors: album.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: album.symbol)
                        .font(.system(size: proxy.size.width * 0.3, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    Color(white: 0.12)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
