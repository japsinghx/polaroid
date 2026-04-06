import SwiftUI

struct BottomBarView: View {
    let onCapture: () -> Void
    let onGallery: () -> Void
    let onFlip: () -> Void
    var lastPhoto: UIImage?
    var filmFull: Bool = false
    var flipRotation: Double = 0

    @GestureState private var isPressed = false

    var body: some View {
        HStack {
            // Gallery thumbnail
            Button(action: onGallery) {
                if let lastPhoto {
                    Image(uiImage: lastPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white, lineWidth: 3)
                            )
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(white: 0.5))
                    }
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
            }
            .frame(maxWidth: .infinity)

            // Red shutter button — uses LongPressGesture+DragGesture for instant visual feedback
            ZStack {
                // Outer metallic ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.95), Color(white: 0.75), Color(white: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(
                        color: .black.opacity(isPressed ? 0.1 : 0.3),
                        radius: isPressed ? 1 : 6,
                        y: isPressed ? 1 : 4
                    )

                // Inner button
                Circle()
                    .fill(
                        filmFull
                        ? RadialGradient(
                            colors: [Color(white: 0.7), Color(white: 0.55)],
                            center: .center, startRadius: 0, endRadius: 32
                        )
                        : RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.2),
                                Color(red: 0.75, green: 0.12, blue: 0.1),
                            ],
                            center: .center, startRadius: 0, endRadius: 32
                        )
                    )
                    .frame(width: 60, height: 60)

                if filmFull {
                    Image(systemName: "nosign")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(isPressed ? 0.1 : 0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 40, height: 20)
                        .offset(y: -12)
                }
            }
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { _ in
                        guard !filmFull else { return }
                        onCapture()
                    }
            )
            .allowsHitTesting(!filmFull)
            .frame(maxWidth: .infinity)

            // Camera flip button
            Button(action: onFlip) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(white: 0.35))
                    .frame(width: 44, height: 44)
                    .background(Color(white: 0.92))
                    .clipShape(Circle())
                    .rotationEffect(.degrees(flipRotation))
                    .animation(.easeInOut(duration: 0.4), value: flipRotation)
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
        )
    }
}
